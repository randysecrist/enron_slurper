-module(enron_map_reduce).
-export([map_key_value/3]).

map_key_value({error, notfound}, _, _) ->
    [];
map_key_value(Object, _Keydata, _Arg) ->
  %Check for siblings
  case riak_object:value_count(Object) of
    1  ->
      MD = riak_object:get_update_metadata(Object),
      %Check for tombstones
      case dict:is_key(<<"X-Riak-Deleted">>, MD) of
        true ->
          [];
        _ ->
          %Get data from object
          Data = riak_object:get_value(Object),
          Key = riak_object:key(Object),  
          [[Key, Data]]
        end;
    _ ->
      Key = riak_object:key(Object),
      [[Key, <<"Siblings">>]]
  end.
