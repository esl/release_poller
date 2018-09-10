# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
~w(rel plugins *.exs)
|> Path.join()
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
  # This sets the default release built by `mix release`
  default_release: :default,
  # This sets the default environment used by `mix release`
  default_environment: Mix.env()

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/config/distillery.html

# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :dev do
  # If you are running Phoenix, you should make sure that
  # server: true is set and the code reloader is disabled,
  # even in dev mode.
  # It is recommended that you build with MIX_ENV=prod and pass
  # the --env flag to Distillery explicitly if you want to use
  # dev mode.
  set(dev_mode: true)
  set(include_erts: false)
  set(cookie: :"[J@<@ww$6YYlNzecLy.Pdq8.kDM(_vvTiEDJb/tVtJY%Zt1c0KsQcLe@jrARRueI")
end

environment :prod do
  set config_providers: [
    {Mix.Releases.Config.Providers.Elixir, ["${RELEASE_ROOT_DIR}/etc/config.exs"]}
  ]

  set(include_erts: false)
  set(include_src: false)
  set(cookie: :"2!!icJ[Bs)bWBqj&BBWWUGm`sfOn|r3a5luB;A0/BVPiGy/MD?R[@(G{5*;$]F=R")
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix release`, the first release in the file
# will be used by default

release :poller do
  set(version: current_version(:repo_poller))

  set overlays: [
    {:copy, "rel/config/pooler.config.exs", "etc/config.exs"}
  ]

  set(
    applications: [
      :runtime_tools,
      bugs_bunny: :permanent,
      domain: :permanent,
      repo_poller: :permanent
    ]
  )
end

release :jobs do
  set(version: current_version(:repo_jobs))

  set overlays: [
    {:copy, "rel/config/jobs.config.exs", "etc/config.exs"}
  ]

  set(
    applications: [
      :runtime_tools,
      bugs_bunny: :permanent,
      domain: :permanent,
      repo_jobs: :permanent
    ]
  )
end
