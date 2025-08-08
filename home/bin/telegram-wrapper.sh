#!/bin/bash
LIBGL_ALWAYS_SOFTWARE=1 /usr/bin/flatpak run --branch=stable --arch=x86_64 --command=Telegram --file-forwarding org.telegram.desktop -- "$@"
