# Server Picker Labels and Shutdown

## Goal

Make `:ShowNvimServers` useful when several Neovim instances are running by
giving each server a recognizable label and allowing unwanted servers to be
closed from the picker.

## Interaction

- Press `R` on a server to enter or change its label.
- Submitting an empty label clears the existing label.
- A labeled row is displayed as `[1] api │ nvim.12345.0 (current)`.
- An unlabeled row continues to display as `[1] nvim.12345.0 (current)`.
- Press `d` on a server to request that it close.
- Every close request requires confirmation and defaults to cancellation.
- Existing `<CR>`, `q`, `<Esc>`, and `<leader>r` behavior remains unchanged.

## Label Ownership

The label belongs to the running Neovim server rather than to the picker that
assigned it. It is stored as a global variable in the target instance and read
through Neovim's RPC API while the list is refreshed.

This makes a label visible from every running instance without adding a
persistence file or leaving stale labels after a server exits. Labels last for
the lifetime of their server.

## RPC Flow

Socket discovery opens a temporary RPC channel to each live server. Refreshing
the list reads the server's label before closing that channel. Renaming opens a
channel to the selected row, updates or deletes the label, closes the channel,
and refreshes the picker.

After close confirmation, the picker sends `qa!` to the selected server over an
asynchronous RPC notification. An asynchronous request avoids treating the
expected channel shutdown as a failed synchronous response. When the picker is
running in a different server, it refreshes after the target has had an
opportunity to remove its socket. Closing the current server naturally ends the
picker along with that Neovim process.

## Safety and Errors

Close confirmation identifies the selected server by label and socket name so
the target is unambiguous. Confirmation is required for remote servers and for
the current server. Cancelling has no side effects.

Connection, label, and shutdown failures are reported with `vim.notify`.
Temporary channels are closed whenever they remain open. A failed operation
does not close the picker or modify another row.

## Testing

Headless Neovim tests will cover row formatting, label reads and writes,
clearing a label, confirmation cancellation, confirmed shutdown dispatch, and
RPC failure handling. Tests will be written first and observed failing before
the implementation is added. Final verification will also load the complete
configuration in headless Neovim and check the diff for formatting errors.
