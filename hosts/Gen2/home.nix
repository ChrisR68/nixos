{ config, pkgs, ... }:

{
  programs.plasma = {
    configFile."kwinrc"."Plugins"."zoomEnabled" = false;
    configFile."kwinrc"."Effect-zoom"."InitalZoom" = 1.0;
    configFile."kwinrc"."Effect-zoom"."ZoomFactor" = 1.0;
    };
}
