# Based on libgit2 examples/init.c
# Similar to 'git init'

use v6;
use lib '../lib';

use Git::LibGit2;
use NativeCall;     # for explicitly-manage

# TODO start here
sub create_initial_commit(git_repository $repo) {
    my git_signature $sig   .= new;
    my git_index $index     .= new;
    my git_oid $tree_id     .= new;
    my git_oid $commit_id   .= new;
    my git_tree $tree       .= new;

    # Initialize a signature
    if git_signature_default($sig, $repo) < 0 {
        die "Couldn't create signature. user.name/user.email set?";
    }

    # Create an empty tree for the commit
    if git_repository_index($index, $repo) < 0 {
        die "Couldn't open repo index";
    }

    # Don't actually add any files, just write index
    if git_index_write_tree($tree_id, $index) < 0 {
        die "Unable to write initial tree from index";
    }

    git_index_free($index);

    if git_tree_lookup($tree, $repo, $tree_id) < 0 {
        die "Couldn't look up initial tree";
    }

    # Create initial commit
    if git_commit_create_v($commit_id, $repo, "HEAD", $sig, $sig, Str,
        "Initial Commit", $tree, 0) < 0 {
        die "Couldn't create initial commit";
    }

    # Cleanup
    git_tree_free($tree);
    git_signature_free($sig);
}

my git_repository $repo .= new;
my Str $path = ".";
explicitly-manage($path);
git_repository_init($repo, $path, 0);

create_initial_commit($repo);

say "Created initial commit";
git_repository_free($repo);
