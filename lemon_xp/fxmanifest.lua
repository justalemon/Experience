fx_version "cerulean"
games { "gta5", "rdr3" }

name "Lemon Experience (lemon_xp)"
author "Lemon <lemon@itslemonchan.com>"
description "Simple experience system for FiveM/RedM"
version "1.0.0"
repository "https://github.com/justalemon/Experience"
license "LGPL-3.0-or-later"

server_script "server.lua"

server_only "yes"

convar_category "lemon_xp" {
    "Configuration",
    {
        { "Storage Method", "lemon_xp_storage", "CV_MULTI", { { "oxmysql", "oxmysql" }, { "json", "json" } } }
    }
}
