# TerminalJ+

The RenkuOS Terminal with inline input methods: text typed with Mozc (or any
input method) is composed and converted where the cursor is, instead of in the
input_server's bottom-line window. It is a separate application
(`application/x-vnd.RenkuOS-TerminalJPlus`, settings in
`~/config/settings/TerminalJ+`), so it lives next to Terminal.

Ported-from: RenkuOS/source src/apps/terminal @ d1c95db0, with the change
"Terminal: make inline input usable and enable it"
Ported-from-license: MIT

Changes from Terminal: the inline input patch, the signature, the name, the
settings folder, and the translations of Terminal relinked for the new
signature.

    make            # cross build, needs a built RenkuOS tree in $RENKU
    make hpkg       # build/terminalj_plus-<version>-x86_64.hpkg
