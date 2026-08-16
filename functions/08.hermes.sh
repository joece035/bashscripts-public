#!/bin/bash
# -- Hermes agent dir
export HM_DIR="$HOME/.hermes"
export hm="$HM_DIR"

hm_() {
hermes "$@"
}
