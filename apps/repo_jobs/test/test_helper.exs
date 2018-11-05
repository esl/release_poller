ExUnit.start()

Mox.defmock(Domain.TaskMockRunner, for: Domain.Tasks.Runners.Runner)
Mox.defmock(Domain.TaskMockSource, for: Domain.Tasks.Sources.Source)
Mox.defmock(Domain.Service.MockDatabase, for: Domain.Services.Database)
