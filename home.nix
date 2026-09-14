{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.plasma-manager.homeManagerModules.plasma-manager
  ];

  home.username = "chh";
  home.homeDirectory = "/home/chh";
  home.stateVersion = "26.05";

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.whitesur-cursors;
    name = "WhiteSur-cursors";
    size = 36;
  };

  # Quickshell declarative configuration
  xdg.configFile."quickshell/shell.qml".text = ''
    import QtQuick
    import QtQuick.Layouts
    import Quickshell
    import Quickshell.Io
    import Quickshell.Wayland

    ShellRoot {
        id: root

        // Data monitor properties
        property string cpuUsage: "0%"
        property string memUsage: "0%"
        property string currentDateTime: ""

        // CPU calculation state
        property var lastCpuTotal: 0
        property var lastCpuIdle: 0

        // Timer for Clock (updates every second)
        Timer {
            interval: 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                root.currentDateTime = Qt.formatDateTime(new Date(), "ddd d MMM hh:mm:ss")
            }
        }

        // Process to read CPU usage from /proc/stat
        Process {
            id: cpuProc
            command: ["cat", "/proc/stat"]
            stdout: SplitParser {
                onRead: data => {
                    var lines = data.split("\n");
                    for (var i = 0; i < lines.length; i++) {
                        var parts = lines[i].trim().split(/\s+/);
                        if (parts[0] === "cpu") {
                            var user = parseInt(parts[1]) || 0;
                            var nice = parseInt(parts[2]) || 0;
                            var system = parseInt(parts[3]) || 0;
                            var idle = parseInt(parts[4]) || 0;
                            var iowait = parseInt(parts[5]) || 0;
                            var irq = parseInt(parts[6]) || 0;
                            var softirq = parseInt(parts[7]) || 0;

                            var currentIdle = idle + iowait;
                            var currentTotal = user + nice + system + idle + iowait + irq + softirq;

                            if (root.lastCpuTotal !== 0) {
                                var totalDiff = currentTotal - root.lastCpuTotal;
                                var idleDiff = currentIdle - root.lastCpuIdle;
                                if (totalDiff > 0) {
                                    var usage = Math.round(100 * (totalDiff - idleDiff) / totalDiff);
                                    root.cpuUsage = usage + "%";
                                }
                            }

                            root.lastCpuTotal = currentTotal;
                            root.lastCpuIdle = currentIdle;
                            break;
                        }
                    }
                }
            }
        }

        // Process to read Memory usage from /proc/meminfo
        Process {
            id: memProc
            command: ["sh", "-c", "awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {if (t>0) printf(\"%.0f%%\\n\", (t-a)/t*100)}' /proc/meminfo"]
            stdout: SplitParser {
                onRead: data => {
                    var trimmed = data.trim();
                    if (trimmed.length > 0) {
                        root.memUsage = trimmed;
                    }
                }
            }
        }

        // Timer to poll CPU and RAM every 2 seconds
        Timer {
            interval: 2000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                cpuProc.running = true;
                memProc.running = true;
            }
        }

        // Launcher Process for KDE System Settings
        Process {
            id: settingsProc
            command: ["systemsettings"]
        }

        // Top Status Bar Panel
        PanelWindow {
            id: bar
            anchors {
                top: true
                left: true
                right: true
            }
            height: 38
            color: "#d01c1d22" // Translucent dark background

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            // Main Layout Container
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                // ================= LEFT ITEMS =================

                // Apple Logo Icon (Click opens KDE System Settings)
                Text {
                    text: "\uf302"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    color: appleMouse.containsMouse ? "#ffffff" : "#d8d8d8"
                    Layout.alignment: Qt.AlignVCenter

                    MouseArea {
                        id: appleMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            settingsProc.running = true;
                        }
                    }
                }

                // Global Application Menus (File, Edit, View, Window, Help)
                Row {
                    spacing: 12
                    Layout.alignment: Qt.AlignVCenter

                    Repeater {
                        model: ["File", "Edit", "View", "Window", "Help"]
                        delegate: Text {
                            text: modelData
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: itemMouse.containsMouse ? "#ffffff" : "#b0b0b0"

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                            }    
                        }
                    }
                }

                // Expanding Spacer (Pushes left and right items apart)
                Item {
                    Layout.fillWidth: true
                }

                // ================= RIGHT ITEMS =================

                // CPU Usage
                Text {
                    text: "CPU: " + root.cpuUsage
                    font.pixelSize: 14
                    font.family: "monospace"
                    color: "#e0e0e0"
                    Layout.alignment: Qt.AlignVCenter
                }

                // Memory Usage
                Text {
                    text: "MEM: " + root.memUsage
                    font.pixelSize: 14
                    font.family: "monospace"
                    color: "#e0e0e0"
                    Layout.alignment: Qt.AlignVCenter
                }

                // Divider
                Rectangle {
                    width: 1
                    height: 14
                    color: "#444444"
                    Layout.alignment: Qt.AlignVCenter
                }

                // Clock: Day Month HH:MM:SS (24-hour format)
                Text {
                    text: root.currentDateTime
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: "#f5f5f7"
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }
  '';

  # Autostart Quickshell with the user graphical session
  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell Desktop Bar";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/quickshell";
      Restart = "always";
      RestartSec = "2s";
    };
  };


# Sublime Text Settings
  xdg.configFile."sublime-text/Packages/User/Preferences.sublime-settings".text = builtins.toJSON {
    color_scheme = "Packages/Color Scheme - Default/Monokai.sublime-color-scheme";
    font_face = "JetBrains Mono";
    font_size = 10;
    theme = "Default Dark.sublime-theme";
    ui_scale = 1.25;
    tab_size = 2;
    translate_tabs_to_spaces = true;
    trim_trailing_white_space_on_save = true;
    # Paste your remaining key/value pairs from macOS here
    index_files = true;
  };

  # Sublime Text Keymaps
  # Note: Convert 'super+' (Cmd) modifiers from macOS to 'ctrl+' or 'alt+' for Linux if desired
  xdg.configFile."sublime-text/Packages/User/Default (Linux).sublime-keymap".text = builtins.toJSON [
    {
      keys = [ "ctrl+shift+r" ];
      command = "reindent";
    }
  ];






  programs.plasma = {
    enable = true;
    workspace = {
      theme = "WhiteSur-dark";
      lookAndFeel = "org.kde.breezedark.desktop";
      iconTheme = "WhiteSur-dark";
      cursor = {
        theme = "WhiteSur-cursors";
        size = 36;
      };
    };

    configFile."ksmserverrc"."General"."loginMode" = "emptySession";
    configFile."kwinrc"."org.kde.kdecoration2"."library" = "org.kde.kwin.aurorae";
    configFile."kwinrc"."org.kde.kdecoration2"."theme" = "kwin4_decoration_qml_plastik";

    configFile."kcminputrc"."Libinput/0/0/spice vdagent tablet"."NaturalScroll" = true;
    configFile."kwinrc"."ModifierOnlyShortcuts"."Meta" = "";

    panels = [
      {
        location = "bottom";
        alignment = "center";
        lengthMode = "fit";
        hiding = "windowscover";
        floating = true;
        height = 56;
        widgets = [
          "org.kde.plasma.icontasks"
        ];
      }
    ];

    shortcuts = {
      services = {
        "firefox.desktop" = "Alt+F";
      };
    };
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake /etc/nixos#nixos";
      edc = "sudo vi /etc/nixos/configuration.nix";
      edh = "sudo vi /etc/nixos/home.nix";
      bak = "/home/chh/nixos-config/bak.sh";
    };
    
    initExtra = ''
      export PS1='[\[\e[36m\]\u\[\e[0m\]]\\$ '
    '';
  };

  programs.alacritty = {
    enable = true;
    settings = {
      window.opacity = 0.98;
      font.size = 12;
      font.normal = {
        family = "JetBrains Mono";
        style = "Regular";
      };
    };
  };

  programs.ghostty = {
    enable = true;
    settings = {
      theme = "Darkside";
      font-family = "JetBrains Mono";
      font-size = 12;
      scrollback-limit = 100000;
      cursor-style = "block";
      cursor-style-blink = false;
      shell-integration-features = "no-cursor";
      window-padding-x = "10,4";
      window-padding-color = "extend";

      keybind = [
        "performable:ctrl+c=copy_to_clipboard"
        "ctrl+v=paste_from_clipboard"
        "ctrl+a=select_all"
        "ctrl+t=new_tab"
        "ctrl+n=new_window"
        "ctrl+f4=close_window"
        "ctrl+1=goto_tab:1"
        "ctrl+2=goto_tab:2"
        "ctrl+3=goto_tab:3"
        "ctrl+4=goto_tab:4"
        "super+a=text:\\x01"
        "super+c=text:\\x03"
        "super+d=text:\\x04"
        "super+e=text:\\x05"
        "super+k=text:\\x0b"
        "super+l=text:\\x0c"
        "super+r=text:\\x12"
        "super+u=text:\\x15"
        "super+v=text:\\x16"
        "super+w=text:\\x17"
        "super+z=text:\\x1a"
      ];
    };
  };

  programs.vim = {
    enable = true;
    defaultEditor = true;
    settings = {
      number = false;
      relativenumber = false;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
    };
    extraConfig = ''
      set clipboard=unnamedplus
      syntax on
      set termguicolors
      colorscheme desert 
      set mouse=a
      set ignorecase
      set smartcase
      set incsearch
    '';
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = false;
    syntaxHighlighting.enable = false;

    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake /etc/nixos#nixos";
      edc = "sudo vi /etc/nixos/configuration.nix";
      edh = "sudo vi /etc/nixos/home.nix";
      bak = "/home/chh/nixos-config/bak.sh";
    };

    history = {
      size = 50000;
      save = 500000;
      share = true;
      ignoreSpace = true;
      ignoreAllDups = true;
      saveNoDups = true;
      ignoreDups = true;
      findNoDups = true;
      append = true;
    };

    sessionVariables = {
      PROMPT_EOL_MARK = "";
      LSCOLORS = "Gxfxcxdxdxegedabagacad";
      FZF_DEFAULT_COMMAND = "(rg --files ~/Documents ~/Downloads /Applications ~/Applications; rg --files .) | awk '!seen[$0]++'";
    };

    initContent = ''
      bindkey -e
      bindkey '^p' history-search-backward
      bindkey '^n' history-search-forward
      bindkey '^w' forward-word
      bindkey '^b' backward-word

      autoload -U compinit
      _comp_options+=(globdots)
      zstyle ':completion:*' menu select
      zmodload zsh/complist
      compinit -u

      precmd() {
        printf "\e]7;%s\e\\" "file://$(hostname)$(pwd)"
      }
    '';
  };

  programs.oh-my-posh = {
    enable = true;
    enableZshIntegration = true;
    configFile = builtins.toFile "my.toml" ''
console_title_template = "{{ .Shell }} in {{ .Folder }}"
version = 3
final_space = true

[[blocks]]
  type = "prompt"
  alignment = "left"
  newline = true

  [[blocks.segments]]
    type = "path"
    style = "plain"
    background = "transparent"
    foreground = "blue"
    template = "{{ .Path }}"

    [blocks.segments.properties]
      style = "full"

  [[blocks.segments]]
    type = "git"
    style = "plain"
    foreground = "p:grey"
    background = "transparent"
    template = " {{ .HEAD }}{{ if or (.Working.Changed) (.Staging.Changed) }}*{{ end }} <cyan>{{ if gt .Behind 0 }}⇣{{ end }}{{ if gt .Ahead 0 }}⇡{{ end }}</>"

    [blocks.segments.properties]
      branch_icon = ""
      commit_icon = "@"
      fetch_status = true

[[blocks]]
  type = "rprompt"
  overflow = "hidden"

  [[blocks.segments]]
    type = "executiontime"
    style = "plain"
    foreground = "yellow"
    background = "transparent"
    template = "{{ .FormattedMs }}"

    [blocks.segments.properties]
      threshold = 5000

[[blocks]]
  type = "prompt"
  alignment = "left"
  newline = true

  [[blocks.segments]]
    type = "text"
    style = "plain"
    foreground_templates = [
      "{{if gt .Code 0}}red{{end}}",
      "{{if eq .Code 0}}magenta{{end}}",
    ]
    background = "transparent"
    template = "❯"

[transient_prompt]
  foreground_templates = [
    "{{if gt .Code 0}}red{{end}}",
    "{{if eq .Code 0}}magenta{{end}}",
  ]
  background = "transparent"
  template = "❯ "

[secondary_prompt]
  foreground = "magenta"
  background = "transparent"
  template = "❯❯ "
    '';
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "ChrisR68";
        email = "flecks.lava_0y@icloud.com";
      };
      init.defaultBranch = "main";
      safe.directory = "/etc/nixos";
    };
  };

  home.packages = with pkgs; [
    home-manager
    bat
    fzf
    ncdu
    fastfetch
    wl-clipboard
    ripgrep
    oh-my-posh
    whitesur-kde
    whitesur-icon-theme
    whitesur-cursors
    quickshell
    qt6.qtwayland
    nerd-fonts.jetbrains-mono
    sublime4
  ];
}
