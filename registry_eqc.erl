-module(registry_eqc).
-compile({parse_transform,eqc_cover}).
-include_lib("eqc/include/eqc.hrl").
-include_lib("eqc/include/eqc_statem.hrl").
-compile(export_all).

-define(names,[a,b,c,d]).

name() ->
  elements(?names).

%% state

-record(state,{pids=[],regs=[]}).

initial_state() ->
  #state{}.

%% spawn

spawn_args(_) ->
  [].

spawn() ->
  spawn_link(timer,sleep,[5000]).

spawn_next(S,Pid,[]) ->
  S#state{pids=S#state.pids++[Pid]}.

%% register

register_pre(S) ->
  S#state.pids /= [].

register_args(S) ->
  [name(),elements(S#state.pids)].

register_pre(S,[Name,Pid]) ->
  not lists:keymember(Name,1,S#state.regs).

register(Name,Pid) ->
  erlang:register(Name,Pid).

register_next(S,_,[Name,Pid]) ->
  S#state{regs=S#state.regs++[{Name,Pid}]}.

%% unregister

unregister_args(_) ->
  [name()].

unregister_pre(S,[Name]) ->
  lists:keymember(Name,1,S#state.regs).

unregister(Name) ->
  erlang:unregister(Name).

%% the property

prop_registry() ->
  ?FORALL(Cmds, commands(?MODULE),
          begin
            [catch erlang:unregister(N) || N <- ?names],
            {H, S, Res} = run_commands(?MODULE,Cmds),
            check_commands(?MODULE, Cmds, {H, S, Res})
          end).
