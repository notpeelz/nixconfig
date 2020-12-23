{ lib, config, pkgs, ... }:

with lib;
{
  imports = [
    ./audio.nix
    ./printscreen.nix
  ];

  config.my.graphical.services.sxhkd = mkIf config.my.graphical.enable {
    enable = true;
    extraPath = makeBinPath (with pkgs; [
      coreutils
      lightdm
      rofi
    ]);
    suppressScriptLogs = false; # set to true to debug
    hotkeys = let
      browserIncognitoParam = "--incognito";
    in (optionals config.my.graphical.wm.bspwm.enable [
      # Change window state
      {
        hotkey = "hyper + t ; {s,f,t,y}";
        cmd = "bspc node -t '~{pseudo_tiled,fullscreen,tiled,floating}'";
      }

      # Toggle sticky
      # FIXME: bspwm doesn't put the tree back in its origin state when moving a
      # sticky node between two desktops
      {
        hotkey = "hyper + t ; h";
        cmd = "bspc node -g sticky";
      }

      # Toggle fullscreen
      {
        hotkey = "hyper + f";
        cmd = "bspc node -t '~fullscreen'";
      }

      # Toggle monocle
      {
        hotkey = "hyper + a";
        cmd = "bspc desktop -l next";
      }

      # Navigate windows with arrows
      {
        hotkey = "{hyper,super} + {_,shift + }{Left,Down,Up,Right}";
        cmd = "{_,_}bspc node -{f,s} {west,south,north,east}";
      }

      # Flip desktop
      {
        hotkey = "hyper + z";
        cmd = "bspc node @/ -F vertical";
      }

      # Rotate desktop
      {
        hotkey = "hyper + {_,shift + }e";
        cmd = "bspc node @/ -R {_,-}90";
      }

      # Rotate windows
      {
        hotkey = "hyper + {_,shift + }r";
        cmd = "bspc node \"$(bspc query -N -n @parent)\" -R {_,-}90";
      }

      # Change desktop on main monitor
      {
        hotkey = "hyper + {1-9}";
        cmd = ''
          cur="$(bspc query --names -D -d)"
          ((cur < 10)) && flag="-f" || flag="-a"
          bspc desktop $flag {0,1,2,3,4,5,6,7,8}
        '';
      }

      # Change desktop on left monitor
      {
        hotkey = "hyper + F{1-9}";
        cmd = ''
          cur="$(bspc query --names -D -d)"
          ((cur >= 10)) && flag="-f" || flag="-a"
          bspc desktop $flag {10-18}
        '';
      }

      # Switch desktop on current monitor
      {
        hotkey = "hyper + d : {1-9}";
        cmd = ''
          cur="$(bspc query --names -D -d)";
          bspc desktop -f $(( (cur >= 10 ? 10 : 0) + {0-8} ))
        '';
      }

      # Move window to desktop
      {
        hotkey = "hyper + shift + {_,F}{1-9}";
        cmd = "bspc node focused -d {_,1}{0-8} --follow";
      }

      # Resize window
      {
        hotkey = "hyper + alt + {Left,Down,Up,Right} : {Left,Down,Up,Right}";
        cmd = "bspc node -z {left,bottom,top,right} {-10 0,0 10,0 -10,10 0}";
      }

      # Close window
      {
        hotkey = "hyper + {_,shift + }BackSpace";
        cmd = "bspc node -{c,k}";
      }

      # Lock session and pause all VLC players
      {
        hotkey = "super + shift + l";
        cmd = ''
          playerctl -a pause
          dm-tool lock
        '';
      }

      # Exit session
      {
        hotkey = "super + alt + BackSpace";
        cmd = "bspc quit";
      }

      # Run desktop programs and commands
      # TODO: create rofi config through nix
      {
        hotkey = "hyper + {_,shift + }space";
        cmd = ''
          rofi -monitor "$(bspc query -M -m --names)" \
            -theme ~/.config/rofi/themes/onedark.rasi \
            {-modi drun -show drun,-modi run -show run}
        '';
      }

      # Cycle through windows
      # TODO: create rofi config through nix
      # TODO (HACK): use special patched version of rofi for alt-tabbing
      {
        hotkey = "alt + Tab";
        cmd = ''
          rofi -monitor "$(bspc query -M -m --names)" \
            -show-icons \
            -theme ~/.config/rofi/themes/onedark.rasi \
            -kb-row-tab 'Alt+Tab,Tab' \
            -modi window,windowcd -show windowcd
        '';
      }

      # Mark window
      {
        hotkey = "hyper + c";
        cmd = "bspc node -g marked=on";
      }

      # Clear marked windows
      {
        hotkey = "hyper + Escape";
        cmd = "bspc node any.marked -g marked=off";
      }

      # Move marked windows
      {
        hotkey = "hyper + v";
        cmd = ''
          while w="$(bspc query -N -n any.marked)"; do
            bspc node "$w".marked -d focused -n focused
            bspc node "$w".marked -g marked=off
          done
        '';
      }

      # Swap marked window
      {
        hotkey = "hyper + x";
        cmd = ''
          bspc node any.marked -s focused
          bspc node any.marked -g marked=off
        '';
      }

      # Open terminal
      {
        hotkey = "hyper + Return";
        cmd = "$TERMINAL";
      }

      # Open browser
      {
        hotkey = "hyper + {_,shift + }n";
        cmd = "$BROWSER{_, ${browserIncognitoParam}}";
      }

      # Change gap
      {
        hotkey = "hyper + {minus,equal}";
        cmd = ''
          gap="$(bspc config -d focused window_gap)"
          bspc config -d focused window_gap $(({gap + 2, gap > 0 ? gap - 2 : 0}))
        '';
      }

      # Reset gap
      {
        hotkey = "hyper + 0";
        cmd = "bspc config -d focused window_gap $BSPWM_GAP";
      }

      # Cycle through monitors
      {
        hotkey = "hyper + g";
        cmd = "bspc monitor -f next";
      }

      # Send window to next monitor
      {
        hotkey = "hyper + shift + g";
        cmd = "bspc node -m next --follow";
      }

      # Swap with biggest window on current monitor
      {
        hotkey = "hyper + w";
        cmd = "bspc node -s biggest.local";
      }
    ]);
  };
}
