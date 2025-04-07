# def filter_item:
#   # can remove fields you don't care about
#   .
# ;

def filter_item:
  {
    id: .id,
    name: .name,
    notes: .notes,
    username: .login.username,
    password: .login.password,
    fields: ((.fields | group_by(.name) | map({(.[0].name): map(.value)}) | add )? // {})
  } + (.card) + (.sshKey)
;
