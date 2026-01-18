#!/usr/bin/env bash
# =============================================================================
# homelab_2026.1 - Catppuccin colours
# =============================================================================
# Purpose
#   Provides Catppuccin colour palette helpers for terminal output.
#
# Usage
#   source scripts/lib/colours.sh
#   colour_init "mocha"  ... flavours: latte|frappe|macchiato|mocha
#
# Developer notes
#   - We map a subset of Catppuccin accents to ANSI 24-bit colours.
#   - If ...
# =============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# Default flavour.
CATPPUCCIN_FLAVOUR="${CATPPUCCIN_FLAVOUR:-mocha}"

# Emoji toggle.
HL_EMOJI="${HL_EMOJI:-1}"

# We keep these as RGB strings.
declare -A HL_PAL=()

_colour_set_palette() {
  local f="$1"
  case "${f}" in
    latte)
      HL_PAL[base]="239 241 245"
      HL_PAL[text]="76 79 105"
      HL_PAL[green]="64 160 43"
      HL_PAL[yellow]="223 142 29"
      HL_PAL[red]="210 15 57"
      HL_PAL[blue]="30 102 245"
      HL_PAL[mauve]="136 57 239"
      ;;
    frappe)
      HL_PAL[base]="48 52 70"
      HL_PAL[text]="198 208 245"
      HL_PAL[green]="166 209 137"
      HL_PAL[yellow]="229 200 144"
      HL_PAL[red]="231 130 132"
      HL_PAL[blue]="140 170 238"
      HL_PAL[mauve]="202 158 230"
      ;;
    macchiato)
      HL_PAL[base]="36 39 58"
      HL_PAL[text]="202 211 245"
      HL_PAL[green]="166 218 149"
      HL_PAL[yellow]="238 212 159"
      HL_PAL[red]="237 135 150"
      HL_PAL[blue]="138 173 244"
      HL_PAL[mauve]="198 160 246"
      ;;
    mocha|*)
      HL_PAL[base]="30 30 46"
      HL_PAL[text]="205 214 244"
      HL_PAL[green]="166 227 161"
      HL_PAL[yellow]="249 226 175"
      HL_PAL[red]="243 139 168"
      HL_PAL[blue]="137 180 250"
      HL_PAL[mauve]="203 166 247"
      ;;
  esac
}

colour_init() {
  local f="$1"
  CATPPUCCIN_FLAVOUR="${f:-${CATPPUCCIN_FLAVOUR}}"
  _colour_set_palette "${CATPPUCCIN_FLAVOUR}"
}

_colour_rgb() {
  # Usage: _colour_rgb "r g b"
  local rgb="$1"
  printf '\033[38;2;%sm' "${rgb// /;}"
}

_colour_reset() { printf '\033[0m'; }

hl_fmt() {
  # Usage: hl_fmt <token> <message>
  local token="$1"; shift || true
  local msg="$*"

  local rgb="${HL_PAL[text]}"
  case "${token}" in
    info) rgb="${HL_PAL[blue]}" ;;
    ok) rgb="${HL_PAL[green]}" ;;
    warn) rgb="${HL_PAL[yellow]}" ;;
    err) rgb="${HL_PAL[red]}" ;;
    accent) rgb="${HL_PAL[mauve]}" ;;
  esac

  printf '%b%s%b' "$(_colour_rgb "${rgb}")" "${msg}" "$(_colour_reset)"
}

hl_emoji() {
  # Usage: hl_emoji <token>
  local token="$1"
  [[ "${HL_EMOJI}" == "1" ]] || { printf '%s' ""; return 0; }

  case "${token}" in
    info) printf 'ℹ️ ' ;;
    ok) printf '✅ ' ;;
    warn) printf '⚠️ ' ;;
    err) printf '🛑 ' ;;
    run) printf '🚀 ' ;;
    ask) printf '🧩 ' ;;
    *) printf '' ;;
  esac
}
