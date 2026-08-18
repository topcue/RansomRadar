# Research notes

## Deferred: target process-tree collection

For controlled experiments, register the launched program as a root process
(`PID`, process start time, `tree_id`) before it begins work. Track process
creation and termination in the kernel, inherit the `tree_id` to every
descendant, and emit IRP events only for live members of that tree.

Keep raw kernel events minimal; a user-mode collector should store the event
stream and join process metadata. Use process start time (or an equivalent
process identity) with PID to prevent PID-reuse errors. Treat code injection,
service/COM delegation, and work performed by pre-existing processes as known
coverage limits. For future real-time detection, define a separate policy for
which newly created processes become candidate roots.
