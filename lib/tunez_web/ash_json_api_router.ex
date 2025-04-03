defmodule TunezWeb.AshJsonApiRouter do
  use AshJsonApi.Router,
    domains: [Module.concat([Tunez.Music]), Module.concat(["Tunez.Accounts"])],
    open_api: "/open_api",
    open_api_title: "Tunez API documentation",
    open_api_version: "#{Application.spec(:tunez, :vsn)}"
end
