{ lib, config, pkgs, ... }:

with lib;
{
  config.my.graphical.services.sxhkd = mkIf config.my.graphical.enable {
    hotkeys = let
      bspc = "${pkgs.bspwm}/bin/bspc";
      awk = "${pkgs.gawk}/bin/awk";
      sed = "${pkgs.gnused}/bin/sed";
      imagemagick-import = "${pkgs.imagemagick}/bin/import";
      xwininfo = "${pkgs.xorg.xwininfo}/bin/xwininfo";
      xrandr = "${pkgs.xorg.xrandr}/bin/xrandr";
      xclip = "${pkgs.xclip}/bin/xclip";
      mktemp = "${pkgs.coreutils}/bin/mktemp";
      rm = "${pkgs.coreutils}/bin/rm";
      spectacle = "${pkgs.spectacle}/bin/spectacle";
    in (optionals config.my.graphical.wm.bspwm.enable [
      # Screenshot of current desktop
      {
        hotkey = "shift + Print";
        cmd = ''
          current_mon="$(${bspc} query --monitors --monitor focused --names)"
          while IFS=' ' read -r mon width height x y; do
            [[ "$current_mon" == "$mon" ]] || continue;
            ${imagemagick-import} -window root -crop "$\{width\}x$\{height\}+$\{x\}+$\{y\}" png:-
              | ${xclip} -selection clipboard -t image/png;
          done < <(
            ${xrandr} -q | grep '\\bconnected\\b'
              | ${sed} -r 's/^([^ ]*).*? ([0-9]+)x([0-9]+)\\+([0-9]+)\\+([0-9]+).*$/\\1 \\2 \\3 \\4 \\5/'
          );
        '';
      }

      # Screenshot of current window
      {
        hotkey = "alt + Print";
        cmd = ''
          id="$(${bspc} query -N -n)"
          border="$(${bspc} config -n focused border_width)"
          while IFS=: read -r field value; do
            # awk is used to trim the whitespaces
            value="$(echo -n "$value" | ${awk} '\{$1=$1;print\}')"
            case "$field" in
              *'Absolute upper-left X') x="$value" ;;
              *'Absolute upper-left Y') y="$value" ;;
              *'Width') width="$value" ;;
              *'Height') height="$value" ;;
            esac
          done < <(${xwininfo} -id "$id")
          ${imagemagick-import} -window root -crop "$\{width\}x$\{height\}+$((x + border))+$((y + border))" png:- \\
            | ${xclip} -selection clipboard -t image/png
        '';
      }

      # Screenshot selection
      {
        hotkey = "Print";
        cmd = ''
          tmp="$(${mktemp})"
          ${spectacle} -r -n -b -o "$tmp"
          ${xclip} -selection clipboard -t image/png -i "$tmp"
          ${rm} "$tmp"
        '';
      }

      # Screenshot of all monitors
      {
        hotkey = "ctrl + shift + Print";
        cmd = ''
          ${imagemagick-import} -window root png:- \
            | ${xclip} -selection clipboard -t image/png
        '';
      }
    ]);
  };
}
