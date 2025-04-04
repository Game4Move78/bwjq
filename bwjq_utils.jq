def is_scalar:
  type != "object" and type != "array" and type != "null"
;

def path_numeric($path):
  $path | map(if test("^[0-9]+$") then tonumber else . end)
;

def getscalar($path):
  if $path[-1] == "" then
    null
  else
    getpath($path)
    | if is_scalar then . else null end
  end
;

def get_siblings($path):
  .
  | getpath($path[:-1])
  | (keys? // [])
  | .[]
  | $path[:-1] + [.]
;

def prefix_depth($prefix):
  ltrimstr($prefix) | gsub("[^/]";"") | length
;

def prefixed_filter($prefix; $recursive):
  . as $path_name
  | select(
        (
          startswith($prefix)
                    and (
                      $recursive
                        or prefix_depth($prefix) == 1
                    )
        ) or (
            $prefix | startswith($path_name)
          )
      )
;

def prefixed_folder($prefix; $recursive):
  (
    .name
    | if endswith("/") then . else . + "/" end
    | prefixed_filter($prefix; $recursive)
  ) as $folder_name
  | [.id, $folder_name]
;

def read_folders:
  label $out
  | fromstream(3|truncate_stream(inputs))
  | (
    if .object == "folder" and .id != null
    then .
    else break $out end
  )
;

def prefixed_item($prefix; $folders; $recursive):
  (
    if .folderId == null then
      "/"
    else
      $folders[.folderId]
      | select(. != null)
    end
  ) as $folder_name
  | (
    .name
    | if endswith("/") then . else . + "/" end
    | sub("/[^/]*$"; "/")
  ) as $item_name
  # | custom::filter_item
  # | select(. != null)
  | . as $item
  | $folder_name + $item_name
  | prefixed_filter($prefix; $recursive)
  | [$folder_name, $item_name, $item]
;

def read_items:
  label $out
  | fromstream(3|truncate_stream(inputs)) as $object
  | (
    if $object.object == "item"
    then $object
    else break $out end
  )
;

def prefixed_path($prefix; $folder; $name; $recursive; $expand; $greedy):
  ($folder + $name) as $prefix_name
  | (
    $prefix
    | (
      if startswith($prefix_name) then
        [
          (
            sub("/[^/]*$"; "/")
          ),(
            ltrimstr($prefix_name)
            | split("/")
          )
        ]
      else
        select($expand)
        | [
          (
            $prefix_name
          ),
          (
            []
          )
        ]
      end
    )
  ) as [$prefix_path, $path]
  | select(
        $recursive
          or $prefix + "/" != $prefix_name
      )
  | (
    if $greedy then
      getscalar($path)
    else
      null
    end
  ) as $value
  | if $value != null then
      select(. != [] and . != {})
      | [$prefix_path, $value]
    else
      (
        if $recursive == true then
          paths(scalars)
        else
          get_siblings($path)
        end
      ) as $path
      | (
        $prefix_name + ($path | join("/"))
        | select(
           (
             startswith($prefix) and . != $prefix)
             or (. == $prefix and ($path | length != 0)
           )
        )
      ) as $prefix_path
      | (
        getpath($path)
        | select(. != null and . != [] and . != {})
      ) as $value
      | $prefix_path
      | if ($value | is_scalar == false) then
          . + "/"
        end
      | [., $value]
    end
;

def folders_map($folders):
  [
    $folders[]
    | {
      "key": (.[0] | tostring),
      "value": (.[1])
    }
  ]
  | from_entries
;

def read_folder_map($prefix; $recursive):
  folders_map([read_folders | prefixed_folder($prefix; $recursive)])
;

def subitems($prefix; $folder; $name):
  $folder + $name
  | . as $prefix_name
  | select(
    startswith($prefix)
    and $prefix != $prefix_name
  )
  | [.]
;

def read_items_from_folder_map($prefix; $recursive):
  . as $folders
  | read_items
  | prefixed_item($prefix; $folders; $recursive)
;

def subitems_and_subpaths($folder; $name; $item; $recursive; $expand; $greedy):
  subitems($prefix; $folder; $name), (
    $item
    | prefixed_path($prefix; $folder; $name; $recursive; $expand; $greedy)
  )
;

def subfolders($prefix; $recursive):
  flatten
  | .[]
  | select(startswith($prefix) and . != $prefix)
  | if $recursive == false then
      select(ltrimstr($prefix) | gsub("[^/]";"") | length <= 1)
    end
| [.]
;
