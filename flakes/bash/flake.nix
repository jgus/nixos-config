{
  description = "Shared bash configuration";

  outputs = { self, ... }:
    let
      promptConfig = ''
        # Color definitions using tput for terminal compatibility
        RED=$(tput setaf 1)
        GREEN=$(tput setaf 2)
        YELLOW=$(tput setaf 3)
        BLUE=$(tput setaf 4)
        RESET=$(tput sgr0)
        if [[ $EUID -eq 0 ]]; then
            USER_COLOR="''${RED}"
        else
            USER_COLOR="''${GREEN}"
        fi

        # Variable to store last exit code
        LAST_EXIT=0

        # PROMPT_COMMAND runs before PS1 is rendered
        PROMPT_COMMAND='LAST_EXIT=$?; '"''${PROMPT_COMMAND}"

        # Function to get git branch
        git_branch() {
            local branch
            branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
            if [[ -n "$branch" && "$branch" != "HEAD" ]]; then
                printf " ''${YELLOW}''${branch}''${RESET}"
            fi
        }

        # Function to show exit code if non-zero (uses saved variable)
        exit_code() {
            if [[ $LAST_EXIT -ne 0 ]]; then
                printf " ''${RED}[''${LAST_EXIT}]''${RESET}"
            fi
        }

        # Set prompt based on user (root or not)
        PS1="''${USER_COLOR}\u@\h''${RESET}:''${BLUE}\w''${RESET}\$(git_branch)\$(exit_code)''${USER_COLOR}\\\$''${RESET} "
      '';
    in
    {
      nixosModules.bash = { config, pkgs, lib, ... }: {
        programs.bash = {
          enable = true;
          promptInit = promptConfig;
        };
      };

      homeModules.bash = { config, pkgs, lib, ... }: {
        programs.bash = {
          enable = true;
          initExtra = promptConfig;
        };
      };
    };
}
