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

def subfolders($folder; $prefix):
  $folder | flatten
  | .[]
  |  select(startswith($prefix) and . != $prefix)
  | if $recursive == "" then
    select(ltrimstr($prefix) | gsub("[^/]";"") | length <= 1)
  end
  | [.]
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

def getscalar($path):
  getpath($path)
  | select(. != null and . != [] and . != {})
  | if is_scalar then . else null end
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

  | (
    $prefix_name
    | select(startswith($prefix) and $prefix_name != $prefix)
    | if $recursive == "" then
      select(ltrimstr($prefix) | gsub("[^/]";"") | length <= 1)
    end
    | [.]
  ), (
     if $expand != "" then
       select($prefix_name | startswith($prefix))
     else
       select($prefix | startswith($prefix_name))
     end
     | ($prefix | sub("/[^/]*$"; "/")) as $prefix_path
     | path_numeric($prefix | ltrimstr($prefix_name) | split("/")) as $path
      | (if $path[-1] != "" then
         getscalar($path)
       else
         null
       end
       ) as $value
    | if $value != null then
        [$prefix_path, $value]
      else (
        if $recursive != "" then
           paths(scalars), []
         else
           ($item | getpath($path[:-1]))
           | (keys? // [])
           | .[]
           | ($path[:-1] + [.])
         end
        ) as $path
        | (
          $prefix_name + ($path | join("/"))
        ) as $prefix_path
        | $item
        | (getscalar($path)) as $value
        | $prefix_path
        | select(
          (startswith($prefix) and . != $prefix)
          or (. == $prefix and ($path | length != 0))
        )
        | if $value == null then
           . + "/"
        end
        | [., $value]
      end
  )
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
| [
  ($folder | values | subfolders(.; $prefix)),
  (
    fromstream(3|truncate_stream(inputs)) as $item
    | entries($folder; $prefix; $item)
)
]
| if (length == 1) and .[0][1] != null and $complete != "" then
  ("value" | select($key != "")), (.[0][1])
elif $all != "" then
  (["tsv"] | select($key != "")), (.[] | select(.[1] != null) | [.[0], .[1]]) | @tsv
else
  ("tree" | select($key != "")), (.[][0])
end
