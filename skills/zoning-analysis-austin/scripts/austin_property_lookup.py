#!/usr/bin/env python3
"""Resolve an Austin address and collect preliminary official GIS screening data."""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
import urllib.parse
import urllib.request
from datetime import date


ADDRESS_URL = "https://maps.austintexas.gov/gis/rest/Shared/Locators/MapServer/0/query"
PARCEL_URL = "https://maps.austintexas.gov/gis/rest/Shared/AppraisalDistricts/MapServer/0/query"
ZONING_URL = "https://maps.austintexas.gov/gis/rest/Shared/Zoning_1/MapServer/0/query"
ORDINANCE_URL = "https://maps.austintexas.gov/gis/rest/Shared/Zoning_1/MapServer/3/query"
ZONING_BY_ADDRESS_URL = "https://data.austintexas.gov/resource/nbzi-qabm.json"

ENVIRONMENTAL_LAYERS = (
    ("fully_developed_floodplain", "Environmental_2", 0),
    ("fema_floodplain", "Environmental_2", 1),
    ("watershed_regulation_area", "Environmental_3", 0),
    ("desired_development_zone", "Environmental_3", 1),
    ("watershed", "Environmental_3", 2),
    ("creek_buffers", "Environmental_3", 3),
    ("aquifer_recharge", "Environmental_3", 4),
    ("aquifer_recharge_verification", "Environmental_3", 5),
    ("aquifer_contributing", "Environmental_3", 6),
    ("erosion_hazard_review_buffer", "Environmental_3", 7),
    ("wetland", "Environmental_1", 2),
    ("rimrock_bluff", "Environmental_1", 3),
    ("cef_setback", "Environmental_1", 7),
)


def request_json(url: str, params: dict[str, object], *, post: bool = True):
    encoded = urllib.parse.urlencode(params)
    request_url = url if post else f"{url}?{encoded}"
    request = urllib.request.Request(
        request_url,
        data=encoded.encode("ascii") if post else None,
        headers={"User-Agent": "AustinZoningSkill/1.0"},
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        payload = json.load(response)
    if "error" in payload:
        raise RuntimeError(f"ArcGIS error from {url}: {payload['error']}")
    return payload


def query_features(url: str, **params: object) -> list[dict]:
    query = {"f": "json", "returnGeometry": "false", "outFields": "*"}
    query.update(params)
    return request_json(url, query).get("features", [])


def first_feature(features: list[dict], label: str) -> dict:
    if not features:
        raise RuntimeError(f"No {label} result returned")
    return features[0]


def address_where(raw_address: str) -> str:
    """Build a locator query from the street portion of a conventional address."""
    street = raw_address.split(",", 1)[0].strip().upper()
    match = re.match(r"^(\d+)\s+(.+)$", street)
    if not match:
        raise ValueError("Address must begin with a numeric street number")
    number, name = match.groups()
    words = [word.rstrip(".") for word in name.split()]
    direction_aliases = {"EAST": "E", "WEST": "W", "NORTH": "N", "SOUTH": "S"}
    type_aliases = {"STREET": "ST", "AVENUE": "AVE", "ROAD": "RD", "BOULEVARD": "BLVD", "DRIVE": "DR"}
    if words:
        words[0] = direction_aliases.get(words[0], words[0])
        words[-1] = type_aliases.get(words[-1], words[-1])
    escaped_full_name = f"{int(number)} {' '.join(words)}".replace("'", "''")
    return f"UPPER(FULL_STREET_NAME) = '{escaped_full_name}'"


def polygon_area_sqft(ring: list[list[float]]) -> float:
    """Calculate a screening area after an equirectangular projection to feet."""
    if len(ring) < 3:
        return 0.0
    lat0 = math.radians(sum(point[1] for point in ring) / len(ring))
    feet_per_degree = 364000.0
    points = [(lon * feet_per_degree * math.cos(lat0), lat * feet_per_degree) for lon, lat in ring]
    twice_area = sum(
        x1 * y2 - x2 * y1
        for (x1, y1), (x2, y2) in zip(points, points[1:] + points[:1])
    )
    return abs(twice_area) / 2.0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("address", help="Austin street address; include ZIP when known")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON")
    args = parser.parse_args()

    address_features = query_features(
        ADDRESS_URL, where=address_where(args.address), outSR=4326, returnGeometry="true"
    )
    address = first_feature(address_features, "address")
    attributes = address.get("attributes", {})
    geometry = address.get("geometry", {})
    lon, lat = geometry.get("x"), geometry.get("y")
    if lon is None or lat is None:
        raise RuntimeError("Address result did not include coordinates")

    point = json.dumps({"x": lon, "y": lat, "spatialReference": {"wkid": 4326}}, separators=(",", ":"))
    spatial = {
        "geometry": point,
        "geometryType": "esriGeometryPoint",
        "inSR": 4326,
        "spatialRel": "esriSpatialRelIntersects",
        "outSR": 4326,
    }
    parcel = first_feature(
        query_features(PARCEL_URL, returnGeometry="true", **spatial), "parcel"
    )
    rings = parcel.get("geometry", {}).get("rings", [])
    if not rings:
        raise RuntimeError("Parcel result did not include polygon geometry")
    all_points = [point for ring in rings for point in ring]
    xmin, xmax = min(p[0] for p in all_points), max(p[0] for p in all_points)
    ymin, ymax = min(p[1] for p in all_points), max(p[1] for p in all_points)
    envelope = f"{xmin},{ymin},{xmax},{ymax}"

    zoning = query_features(ZONING_URL, **spatial)
    ordinances = query_features(ORDINANCE_URL, **spatial)

    environmental = {}
    for key, service, layer_id in ENVIRONMENTAL_LAYERS:
        url = f"https://maps.austintexas.gov/gis/rest/Shared/{service}/MapServer/{layer_id}/query"
        features = query_features(
            url,
            geometry=envelope,
            geometryType="esriGeometryEnvelope",
            inSR=4326,
            spatialRel="esriSpatialRelIntersects",
        )
        environmental[key] = {
            "screening_method": "parcel bounding envelope; may over-report edge intersections",
            "intersects": bool(features),
            "features": [feature.get("attributes", {}) for feature in features],
            "source": url.rsplit("/query", 1)[0],
        }

    place_id = attributes.get("PLACE_ID")
    locator = []
    if place_id is not None:
        locator = request_json(ZONING_BY_ADDRESS_URL, {"place_id": place_id}, post=False)

    parcel_attributes = parcel.get("attributes", {})
    result = {
        "status": "screening_only",
        "access_date": date.today().isoformat(),
        "input_address": args.address,
        "address": {"attributes": attributes, "coordinates_wgs84": [lon, lat], "source": ADDRESS_URL.rsplit("/query", 1)[0]},
        "parcel": {
            "attributes": parcel_attributes,
            "geometry_wgs84": rings,
            "bounding_envelope_wgs84": [xmin, ymin, xmax, ymax],
            "calculated_area_sqft": round(sum(polygon_area_sqft(ring) for ring in rings)),
            "calculated_area_acres": round(sum(polygon_area_sqft(ring) for ring in rings) / 43560.0, 3),
            "area_method": "screening calculation from GIS geometry; verify against survey or legal record",
            "source": PARCEL_URL.rsplit("/query", 1)[0],
        },
        "zoning": {
            "gis_features": [feature.get("attributes", {}) for feature in zoning],
            "address_locator_only": locator,
            "source": ZONING_URL.rsplit("/query", 1)[0],
        },
        "ordinances_at_address_point": {
            "features": [feature.get("attributes", {}) for feature in ordinances],
            "instruction": "Retrieve and read every ordinance and amendment; a CO suffix does not disclose its restrictions.",
            "source": ORDINANCE_URL.rsplit("/query", 1)[0],
        },
        "environmental_screening": environmental,
    }
    json.dump(result, sys.stdout, indent=2 if args.pretty else None, ensure_ascii=False)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, OSError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)
