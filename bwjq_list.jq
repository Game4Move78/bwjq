def folders_entries($folder):
    $folder
    | (
      if .id != null then (.name | tostring) else "" end
      | if endswith("/") then . else . + "/" end
      | sub("/[^/]*$"; "/")
    ) as $folder_name
  | select(
        ($folder_name | startswith($prefix))
          or ($prefix | startswith($folder_name))
      )
  | {"key": (.id | tostring) , "value": ($folder_name)}
;

def path_numeric($path):
  $path | map(if test("^[0-9]+$") then tonumber else . end)
;

def getpath_numeric($path):
  getpath(path_numeric($path))
;

def is_scalar:
  type != "object" and type != "array" and type != "null"
;

def entries($folder; $prefix; $item):
  $item
  | ($folder[(.folderId)? | tostring]?) as $prefix_folder
  | select($prefix_folder != null)
  | (
    .name
    | if endswith("/") then . else . + "/" end
    | sub("/[^/]*$"; "/")
  ) as $item_name
  | ($prefix_folder + $item_name) as $prefix_name
  | if ($prefix_name | startswith($prefix)) then
      $item
      | to_entries[]
      | [.key, .value]
    elif ($prefix | startswith($prefix_name)) then
      (
        $prefix
        | ltrimstr($prefix_name)
        | sub("/$"; "")
      ) as $prefix_path
      | path_numeric($prefix | ltrimstr($prefix_name) | split("/")) as $path
      | $item | getpath($path) as $value
      | $value
      | if is_scalar then
          [$prefix_path, $value]
        else
          to_entries[]
          | [$prefix_path + "/" + .key, .value]
        end
    else
      select(false)
    end
    | {folder: $prefix_folder, name: $item_name, path: .[0], value: .[1]}
;

[
  label $out
  | fromstream(3|truncate_stream(inputs)) as $object
  | (
    if $object.object == "folder"
    then folders_entries($object)
    else break $out end
  )
]
| from_entries as $folder
| $folder
| fromstream(3|truncate_stream(inputs)) as $item
| entries($folder; $prefix; $item)
