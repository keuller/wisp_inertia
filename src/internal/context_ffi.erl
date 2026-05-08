-module(context_ffi).
-export([ctx_erase/1, ctx_get/1, ctx_add/2, sharedctx_add/2, sharedctx_get/1]).

ctx_erase(Key) ->
    persistent_term:erase({inertia_context, Key}).

ctx_get(Key) ->
    try persistent_term:get({inertia_context, Key}) of
        Val -> {ok, Val}
    catch
        error:badarg -> {error, nil}
    end.

ctx_add(Key, Val) ->
    persistent_term:put({inertia_context, Key}, Val),
    persistent_term:get({inertia_context, Key}).

sharedctx_add(Key, Val) ->
    persistent_term:put({inertia_shared, Key}, Val),
    persistent_term:get({inertia_shared, Key}).

sharedctx_get(Key) ->
    try persistent_term:get({inertia_shared, Key}) of
        Val -> {ok, Val}
    catch
        error:badarg -> {error, nil}
    end.
