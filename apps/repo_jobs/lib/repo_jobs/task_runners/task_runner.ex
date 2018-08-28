defmodule RepoJobs.TaskRunners.TaskRunner do
  @callback exec(task :: Task.t(), env :: keyword()):: :ok | no_return()
end
