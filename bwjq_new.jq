import "bwjq_utils" as utils;

[$recursive != "", $expand != "", $greedy != "", $key != "", $all != ""] as [$recursive, $expand, $greedy, $key, $all]
| (
  foreach (
      utils::read_folder_map($prefix; $recursive)
      | (utils::subfolders($prefix; $recursive)
         , utils::read_items_from_folder_map($prefix; $recursive; $expand; $greedy), null)
  ) as $item (
    [null, null];
    [$item, .[0], .[1]];
    select(.[1] != null)
    | if .[0] == null and .[2] == null then
        [true, true, .[1]]
      elif .[2] == null and .[0] != null then
        [true, false, .[1]],
        [false, false, .[0]]
      else
        select(.[0] != null)
        | [false, false, .[0]]
      end
    )
) as [$is_first, $is_one, $elem]
  | $elem
  | if $is_one and .[1] != null and $greedy then
      ("value" | select($is_first and $key)), (.[1])
    elif $all then
      (["tsv"] | select($is_first and $key) | @tsv), (select(.[1] | utils::is_scalar) | @tsv)
    else
      ("tree" | select($is_first and $key)), (.[0])
    end
