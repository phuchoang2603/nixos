let
  inherit (import ../lib.nix)
    appdata
    media
    secrets
    domain
    tz
    proxyNetwork
    ;
in
{
  inherit
    appdata
    media
    secrets
    domain
    tz
    proxyNetwork
    ;

  fqdn = name: "${name}.${domain}";

  mkContainer =
    {
      extraOptions ? [ ],
      environment ? { },
      labels ? { },
      traefik ? null,
      ...
    }@args:
    let
      rest = builtins.removeAttrs args [
        "extraOptions"
        "environment"
        "labels"
        "traefik"
      ];
    in
    rest
    // {
      autoStart = args.autoStart or true;
      extraOptions = [ "--network=${proxyNetwork}" ] ++ extraOptions;
      environment = {
        TZ = tz;
      }
      // environment;
      labels =
        (
          if traefik == null then
            { }
          else
            let
              name = traefik.name;
              host = traefik.host or "${name}.${domain}";
            in
            {
              "traefik.enable" = "true";
              "traefik.http.routers.${name}.rule" = "Host(`${host}`)";
              "traefik.http.routers.${name}.entrypoints" = "websecure";
              "traefik.http.routers.${name}.tls" = "true";
              "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
              "traefik.http.services.${name}.loadbalancer.server.port" = toString traefik.port;
            }
        )
        // labels;
    };
}
