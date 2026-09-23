#!/usr/bin/env bash
# ==============================================================================
# agent-skills installer script
# Easily install or link skills to your global agent config or project workspace
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${SCRIPT_DIR}/skills"
GLOBAL_TARGET="${HOME}/.gemini/config/skills"

print_header() {
  echo "================================================================================"
  echo "                        🤖 AGENT SKILLS REPOSITORY                              "
  echo "================================================================================"
}

print_help() {
  print_header
  echo "Usage: ./install.sh [OPTION] [TARGET_PATH]"
  echo ""
  echo "Options:"
  echo "  --global, -g           Install skills globally to ~/.gemini/config/skills"
  echo "  --link-global, -lg     Symlink skills globally to ~/.gemini/config/skills (live updates)"
  echo "  --project, -p <path>   Install skills into a workspace (<path>/.agents/skills)"
  echo "  --link-project <path>  Symlink skills into a workspace (<path>/.agents/skills)"
  echo "  --list, -l             List all available skills in this repository"
  echo "  --help, -h             Show this help message"
  echo ""
  echo "Examples:"
  echo "  ./install.sh --global"
  echo "  ./install.sh --link-global"
  echo "  ./install.sh --project /home/user/my-web-app"
  echo "  ./install.sh --list"
  echo "================================================================================"
}

list_skills() {
  echo "Available skills in repository:"
  echo "--------------------------------------------------------------------------------"
  python3 -c '
import os

base = "'"${SKILLS_DIR}"'"
for item in sorted(os.listdir(base)):
    if item.startswith("_"):
        continue
    p = os.path.join(base, item, "SKILL.md")
    if os.path.exists(p):
        with open(p) as f:
            content = f.read()
        desc = ""
        if content.startswith("---"):
            lines = content.split("---")[1].strip().split("\n")
            in_desc = False
            desc_lines = []
            for line in lines:
                if line.startswith("description:"):
                    in_desc = True
                    val = line.split("description:", 1)[1].strip(" >-")
                    if val:
                        desc_lines.append(val)
                elif in_desc:
                    if line.startswith(" ") or line.startswith("\t"):
                        desc_lines.append(line.strip())
                    else:
                        break
            desc = " ".join(desc_lines)
        print(f"  \033[1;36m• {item:<34}\033[0m")
        if desc:
            print(f"    \033[0;37m{desc}\033[0m\n")
'
  echo "--------------------------------------------------------------------------------"
}

install_copy() {
  local target="$1"
  echo "📦 Copying skills to: ${target}"
  mkdir -p "${target}"

  for skill_path in "${SKILLS_DIR}"/*; do
    if [ -d "${skill_path}" ] && [ "$(basename "${skill_path}")" != "_template" ]; then
      skill_name="$(basename "${skill_path}")"
      rm -rf "${target}/${skill_name}"
      cp -r "${skill_path}" "${target}/"
      echo "  ✓ Installed: ${skill_name}"
    fi
  done
  echo "✨ Done! Skills successfully installed to ${target}."
}

install_link() {
  local target="$1"
  echo "🔗 Symlinking skills to: ${target}"
  mkdir -p "${target}"

  for skill_path in "${SKILLS_DIR}"/*; do
    if [ -d "${skill_path}" ] && [ "$(basename "${skill_path}")" != "_template" ]; then
      skill_name="$(basename "${skill_path}")"
      rm -rf "${target}/${skill_name}"
      ln -s "${skill_path}" "${target}/${skill_name}"
      echo "  ✓ Linked: ${skill_name} -> ${skill_path}"
    fi
  done
  echo "✨ Done! Skills successfully linked to ${target}."
}

# Main routing
if [ $# -eq 0 ]; then
  print_help
  exit 0
fi

case "$1" in
  --global|-g)
    print_header
    install_copy "${GLOBAL_TARGET}"
    ;;
  --link-global|-lg)
    print_header
    install_link "${GLOBAL_TARGET}"
    ;;
  --project|-p)
    if [ -z "${2:-}" ]; then
      echo "Error: Target project path required."
      echo "Usage: ./install.sh --project /path/to/project"
      exit 1
    fi
    print_header
    install_copy "${2}/.agents/skills"
    ;;
  --link-project)
    if [ -z "${2:-}" ]; then
      echo "Error: Target project path required."
      echo "Usage: ./install.sh --link-project /path/to/project"
      exit 1
    fi
    print_header
    install_link "${2}/.agents/skills"
    ;;
  --list|-l)
    print_header
    list_skills
    ;;
  --help|-h)
    print_help
    ;;
  *)
    echo "Unknown option: $1"
    print_help
    exit 1
    ;;
esac
