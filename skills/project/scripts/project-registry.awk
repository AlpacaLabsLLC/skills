BEGIN {
  FS = "|"
  OFS = "\t"
  required[1] = "Project ID"
  required[2] = "Project"
  required[3] = "Client"
  required[4] = "Code"
  required[5] = "Type"
  required[6] = "Status"
  required[7] = "Folder"
  required[8] = "Opened"
}

function trim(value) {
  gsub(/^[ \t]+|[ \t]+$/, "", value)
  return value
}

function fail(message) {
  if (!failed) print "project registry: " message > "/dev/stderr"
  failed = 1
  exit 3
}

/<!-- projects:start -->/ {
  starts++
  if (starts != 1 || inside) fail("projects:start marker is duplicated or nested")
  inside = 1
  next
}

/<!-- projects:end -->/ {
  ends++
  if (!inside || ends != 1) fail("projects:end marker is unmatched or duplicated")
  inside = 0
  next
}

inside && /^\|/ {
  if (!header_seen) {
    for (i = 2; i < NF; i++) {
      heading = trim($i)
      if (heading in column) fail("duplicate header: " heading)
      column[heading] = i
    }
    for (i = 1; i <= 8; i++) {
      if (!(required[i] in column)) fail("missing required header: " required[i])
    }
    header_seen = 1
    next
  }

  project_id = trim($(column["Project ID"]))
  if (project_id ~ /^:?-+:?$/) next
  if (project_id == "") fail("project row has no Project ID")
  print project_id,
        trim($(column["Project"])),
        trim($(column["Client"])),
        trim($(column["Code"])),
        trim($(column["Type"])),
        trim($(column["Status"])),
        trim($(column["Folder"])),
        trim($(column["Opened"]))
  rows++
  next
}

END {
  if (failed) exit 3
  if (starts != 1 || ends != 1 || inside) fail("exactly one bounded projects section is required")
  if (!header_seen) fail("projects section has no table header")
}
