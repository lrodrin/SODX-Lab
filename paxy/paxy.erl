-module(paxy).
-export([start/1, crash/2, stop/0, stop/1]).
-define(RED, {255,0,0}).
-define(GREEN, {0,255,0}).
-define(BLUE, {0,0,255}).
-define(MAGENTA, {0, 255, 255}).
-define(CYAN, {255, 0, 255}).

start(Seed) ->
    AcceptorNames = ["Acceptor 1", "Acceptor 2", "Acceptor 3","Acceptor 4", "Acceptor 5", "Acceptor 6", "Acceptor 7"],
    AccRegister = [a, b, c, d, e, f, g],
    ProposerNames = ["Proposer 1", "Proposer 2", "Proposer 3", "Proposer 4", "Proposer 5"],
    PropInfo = [{kurtz, ?RED, 10}, {kilgore, ?GREEN, 2}, {willard, ?BLUE, 3}, {bill, ?CYAN, 21}, {zorro, ?MAGENTA, 32}],
    % computing panel heights
    AccPanelHeight = length(AcceptorNames)*50 + 20, %plus the spacer value
    PropPanelHeight = length(ProposerNames)*50 + 20,
    register(gui, spawn(fun() -> gui:start(AcceptorNames, ProposerNames,
    AccPanelHeight, PropPanelHeight) end)),
    gui ! {reqState, self()},
    receive
        {reqState, State} ->
            {AccIds, PropIds} = State,
            start_acceptors(AccIds, AccRegister, Seed),
            start_proposers(PropIds, PropInfo, AccRegister, Seed+1)
    end,
    true.
start_acceptors(AccIds, AccReg, Seed) ->
    case AccIds of
        [] ->
            ok;
        [AccId|Rest] ->
            [RegName|RegNameRest] = AccReg,
            register(RegName, acceptor:start(RegName, Seed, AccId)),
            start_acceptors(Rest, RegNameRest, Seed+1)
    end.
start_proposers(PropIds, PropInfo, Acceptors, Seed) ->
    case PropIds of
        [] ->
            ok;
        [PropId|Rest] ->
            [{RegName, Colour, Inc}|RestInfo] = PropInfo,
            proposer:start(RegName, Colour, Acceptors, Seed+Inc, PropId),
            start_proposers(Rest, RestInfo, Acceptors, Seed)
        end.
stop() ->
    stop(gui),
    stop(a),
    stop(b),
    stop(c),
    stop(d),
    stop(e).
stop(Name) ->
    case whereis(Name) of
        undefined ->
            ok;
        Pid ->
            Pid ! stop
    end.

crash(Name, Seed) ->
  case whereis(Name) of
    undefined ->
      ok;
    Pid ->
      io:format("Acceptor with name ~s crashed~n", [Name]),
      unregister(Name),
      exit(Pid, "crash"),
      register(Name, acceptor:start(Name, Seed, na))
  end.
