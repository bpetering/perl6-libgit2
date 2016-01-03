use v6;

module Git::LibGit2 {

my Str $libname;        # Library name to give to NativeCall
my Version $apivers;    # API version of library so NativeCall doesn't whinge
BEGIN {
    $libname = 'git2';  # libgit2
    $apivers = v23;     # lib<$libname>.so.23
}

use NativeCall;


# TODO
# bpetering, you may find (in the case of an unexpected
#                     segfault) that perl6-gdb-m and/or perl6-valgrind-m may help




# questions:
# - should I be using uint32 as approipriate
# - use is repr cpointer vs is pointer
# - any way besides subset of Int to enforce unsigned?
# - any weird areas with C semantics - volatile etc
# - bitfields in structs
# - threading

# API sections and completion status (default not started)
# Y=yes
# P=partial

# annotated
# attr
# blame
# blob
# branch
# buf
# checkout
# cherrypick
# clone
# commit
# config
# cred
# describe
# diff
# fetch
# filter
# giterr
# graph
# hashsig
# ignore
# index................P
# indexer
# libgit2..............P
# mempack
# merge
# message
# note
# object
# odb
# oid
# oidarray
# openssl
# packbuilder
# patch
# pathspec
# push
# rebase
# refdb
# reference
# reflog
# refspec
# remote
# repository.........P
# reset
# revert
# revparse
# revwalk
# signature..........P
# smart
# stash
# status
# strarray
# stream
# submodule
# tag
# trace
# transport
# tree...............P
# treebuilder


# ### Fundamental types and structures

# # -- src/thread-utils.h --
# # typedef struct {
# # #if defined(GIT_WIN32)
# #     volatile long val;
# # #else
# #     volatile int val;
# # #endif
# # } git_atomic;

# # TODO  Win32 can jump in a lake for now
# class git_atomic is repr('CStruct') is export {
#     has int32 $.val;
# }

# # -- src/thead-utils.h --
# # typedef struct {
# # #if defined(GIT_WIN32)
# #     __int64 val;
# # #else
# #     int64_t val;
# # #endif
# # } git_atomic64;

# class git_atomic64 is repr('CStruct') is export {
#     has int64 $.val;
# }

# # -- src/thead-utils.h --
# # typedef git_atomic git_atomic_ssize;
# # typedef git_atomic64 git_atomic_ssize;

# # TODO 32 ^


# # typedef struct {
# #     git_atomic refcount;
# #     void *owner;
# # } git_refcount;

# class git_refcount is repr('CStruct') is export {
#     has git_atomic $.refcount;
#     has Pointer[void] $.owner;
# }

# # -- src/vector.h --
# # typedef int (*git_vector_cmp)(const void *, const void *);
# # typedef struct git_vector {
# #     size_t _alloc_size;
# #     git_vector_cmp _cmp;
# #     void **contents;
# #     size_t length;
# #     uint32_t flags;
# # } git_vector;
# class git_vector is repr('CStruct') is export {
#     has size_t $._alloc_size;
#     has int32 &._cmp(Pointer[void], Pointer[void]);     # TODO const
#     has Pointer[Pointer[void]] $.contents;
#     has size_t $.length;
#     has uint32 $.flags;
# }

# # -- src/khash.h --
# # #define __KHASH_TYPE(name, khkey_t, khval_t) \
# #     typedef struct kh_##name##_s { \
# #         khint_t n_buckets, size, n_occupied, upper_bound; \
# #         khint32_t *flags; \
# #         khkey_t *keys; \
# #         khval_t *vals; \
# #     } kh_##name##_t;

# # #define khash_t(name) kh_##name##_t

# # -- src/oidmap.h --
# # __KHASH_TYPE(oid, const git_oid *, void *)
# # typedef khash_t(oid) git_oidmap;


# # -- src/thread-utils.h --
# #define git_rwlock pthread_rwlock_t

# # -- src/cache.h --
# # typedef struct {
# #     git_oidmap *map;
# #     git_rwlock  lock;
# #     ssize_t     used_memory;
# # } git_cache;
# class git_cache is repr('CStruct') is export {
#     # TODO map
#     has size_t $.lock;              # TODO really pthread_rwlock_t - stop guessing
#     has size_t $.used_memory;       # TODO signedness?
# }

# # struct git_odb {
# #     git_refcount rc;
# #     git_vector backends;
# #     git_cache own_cache;
# # };

# # typedef struct git_odb git_odb;
# class git_odb is repr('CStruct') is export {
#     has git_refcount    $.rc;
#     has git_vector      $.backends;
#     has git_cache       $.own_cache;
# }

# # -- include/git2/types.h --
# # typedef struct git_refdb_backend git_refdb_backend;

# # -- include/git2/sys/refdb_backend.h --
# # :( :(
# # struct git_refdb_backend {
# # ...



# #     /**
# #      * Queries the refdb backend for a given reference.  A refdb
# #      * implementation must provide this function.
# #      */
# #     int (*lookup)(
# #         git_reference **out,
# #         git_refdb_backend *backend,
# #         const char *ref_name);

# #     /**
# #      * Allocate an iterator object for the backend.
# #      *
# #      * A refdb implementation must provide this function.
# #      */
# #     int (*iterator)(
# #         git_reference_iterator **iter,
# #         struct git_refdb_backend *backend,
# #         const char *glob);

# #     /*
# #      * Writes the given reference to the refdb.  A refdb implementation
# #      * must provide this function.
# #      */
# #     int (*write)(git_refdb_backend *backend,
# #              const git_reference *ref, int force,
# #              const git_signature *who, const char *message,
# #              const git_oid *old, const char *old_target);

# #     int (*rename)(
# #         git_reference **out, git_refdb_backend *backend,
# #         const char *old_name, const char *new_name, int force,
# #         const git_signature *who, const char *message);

# #     /**
# #      * Deletes the given reference from the refdb.  A refdb implementation
# #      * must provide this function.
# #      */
# #     int (*del)(git_refdb_backend *backend, const char *ref_name, const git_oid *old_id, const char *old_target);

# #     /**
# #      * Suggests that the given refdb compress or optimize its references.
# #      * This mechanism is implementation specific.  (For on-disk reference
# #      * databases, this may pack all loose references.)    A refdb
# #      * implementation may provide this function; if it is not provided,
# #      * nothing will be done.
# #      */
# #     int (*compress)(git_refdb_backend *backend);

# #     /**
# #      * Query whether a particular reference has a log (may be empty)
# #      */
# #     int (*has_log)(git_refdb_backend *backend, const char *refname);

# #     /**
# #      * Make sure a particular reference will have a reflog which
# #      * will be appended to on writes.
# #      */
# #     int (*ensure_log)(git_refdb_backend *backend, const char *refname);

# #     /**
# #      * Frees any resources held by the refdb.  A refdb implementation may
# #      * provide this function; if it is not provided, nothing will be done.
# #      */
# #     void (*free)(git_refdb_backend *backend);

# #     /**
# #      * Read the reflog for the given reference name.
# #      */
# #     int (*reflog_read)(git_reflog **out, git_refdb_backend *backend, const char *name);

# #     /**
# #      * Write a reflog to disk.
# #      */
# #     int (*reflog_write)(git_refdb_backend *backend, git_reflog *reflog);

# #     /**
# #      * Rename a reflog
# #      */
# #     int (*reflog_rename)(git_refdb_backend *_backend, const char *old_name, const char *new_name);

# #     /**
# #      * Remove a reflog.
# #      */
# #     int (*reflog_delete)(git_refdb_backend *backend, const char *name);

# #     /**
# #      * Lock a reference. The opaque parameter will be passed to the unlock function
# #      */
# #     int (*lock)(void **payload_out, git_refdb_backend *backend, const char *refname);

# #     /**
# #      * Unlock a reference. Only one of target or symbolic_target
# #      * will be set. success indicates whether to update the
# #      * reference or discard the lock (if it's false)
# #      */
# #     int (*unlock)(git_refdb_backend *backend, void *payload, int success, int update_reflog,
# #               const git_reference *ref, const git_signature *sig, const char *message);
# # };
# class git_refdb_backend is repr('CStruct') is export {
#     #     unsigned int version;
#     has uint32 $.version;

#     #     /**
#     #      * Queries the refdb backend to determine if the given ref_name
#     #      * exists.  A refdb implementation must provide this function.
#     #      */
#     #     int (*exists)(
#     #         int *exists,
#     #         git_refdb_backend *backend,
#     #         const char *ref_name);

#     #has int32 $.exists

# }

# # -- include/git2/types.h --
# # typedef struct git_refdb git_refdb;

# # -- src/refdb.h --
# # struct git_refdb {
# #     git_refcount rc;
# #     git_repository *repo;
# #     git_refdb_backend *backend;
# # };
# class git_refdb is repr('CStruct') is export {
#     has git_refcount                $.rc;
#     has Pointer[git_repository]     $.repo;
#     has Pointer[git_refdb_backend]  $.backend;
# }

# # struct git_repository {
# #     git_odb *_odb;
# #     git_refdb *_refdb;
# #     git_config *_config;
# #     git_index *_index;

# #     git_cache objects;
# #     git_attr_cache *attrcache;
# #     git_diff_driver_registry *diff_drivers;

# #     char *path_repository;
# #     char *path_gitlink;
# #     char *workdir;
# #     char *namespace;

# #     char *ident_name;
# #     char *ident_email;

# #     git_array_t(git_buf) reserved_names;

# #     unsigned is_bare:1;

# #     unsigned int lru_counter;

# #     git_atomic attr_session_key;

# #     git_cvar_value cvar_cache[GIT_CVAR_CACHE_MAX];
# # };

# # typedef struct git_repository git_repository;

# class git_repository is repr('CStruct') is export {
#     has Pointer[git_odb] $._odb;

#     has Str $.path_repository;
#     has Str $.path_gitlink;
#     has Str $.workdir;
#     has Str $.namespace;

#     has Str $.ident_name;
#     has Str $.ident_email;

#     # TODO reserved_names

#     has uint8   $.is_bare;    # TODO packing/size/type
#     has uint32  $lru_counter;

#     has git_atomic $.attr_session_key;

#     # TODO git_cvar_value
# }


# # struct git_object {
# #     git_cached_obj cached;
# #     git_repository *repo;
# # };
# class git_object is repr('CStruct') is export {
#     has Pointer[git_repository] $.repo;
# }

# # typedef struct git_index git_index;
# class git_index is repr('CPointer')
#     is export
#     { }

# # typedef struct git_tree git_tree;
# class git_tree is repr('CPointer')
#     is export
#     { }


# # /** Time in a signature */
# # typedef struct git_time {
# #     git_time_t time; /**< time in seconds from epoch */
# #     int offset; /**< timezone offset, in minutes */
# # } git_time;
# class git_time is repr('CStruct') is export {
#     has int64 $.time;
#     has int32 $.offset;
# }


# # /** An action signature (e.g. for committers, taggers, etc) */
# # typedef struct git_signature {
# #     char *name; /**< full name of the author */
# #     char *email; /**< email of the author */
# #     git_time when; /**< time when the action happened */
# # } git_signature;
# class git_signature is repr('CStruct') is export {
#     has Str $.name;
#     has Str $.email;
#     has git_time $.when;
# }


# We can hand-wave away opaque pointers with "is repr('CPointer')",
# but TANSTAAFL. libgit2 expects certain things to have storage allocated
# already. git_oid is one

# /** Unique identity of any object (commit, tree, blob, tag). */
# typedef struct git_oid {
#     /** raw binary formatted id */
#     unsigned char id[GIT_OID_RAWSZ];
# } git_oid;
class git_oid is repr('CStruct') is export {
    has CArray[uint8] $.id;
}


# # typedef struct {
# #     unsigned int version;
# #     uint32_t    flags;
# #     uint32_t    mode;
# #     const char *workdir_path;
# #     const char *description;
# #     const char *template_path;
# #     const char *initial_head;
# #     const char *origin_url;
# # } git_repository_init_options;
# class git_repository_init_options is repr('CStruct') is export {
#     has uint32 $.version;
#     has uint32 $.flags;
#     has uint32 $.mode;
#     has Str $.workdir_path;     # TODO const/explicitly-manage for all these
#     has Str $.description;
#     has Str $.template_path;
#     has Str $.initial_head;
#     has Str $.origin_url;
# }




### API section: libgit2

sub git_libgit2_init()
    returns int32
    is native($libname, $apivers)
    is export
    { * }

sub git_libgit2_shutdown()
    returns int32
    is native($libname, $apivers)
    is export
    { * }

sub git_libgit2_features()
    returns int32
    is native($libname, $apivers)
    is export
    { * }

sub git_libgit2_version(int32 is rw, int32 is rw, int32 is rw)
    is native($libname, $apivers)
    is export
    { * }

# # next:
# # git_repository type
# # options struct (see http://libgit2.github.com/libgit2/#HEAD/type/git_repository_init_options)

# # git_repository_path()
# # git_repository_workdir()

# # git_signature type
# # git_index type
# # git_oid type
# # git_tree type

# # git_signature_default()
# # git_repository_index()
# # git_index_write_tree()
# # git_index_free()
# # git_tree_lookup()
# # git_commit_create_v()
# # git_tree_free()
# # git_signature_free()

# Fundamental types

class git_repository is repr('CPointer')
    is export
    { }

class git_index is repr('CPointer')
    is export
    { }

class git_tree is repr('CPointer')
    is export
    { }

class git_signature is repr('CPointer')
    is export
    { }

# ### API Section: repository



# int git_repository_init(git_repository **out, const char *path, unsigned int is_bare);
sub git_repository_init(git_repository is rw, Str, uint32)
    returns int32
    is native($libname, $apivers)
    is export
    { * }        # TODO explicitly-manage($path)

# # void git_repository_free(git_repository *repo);
sub git_repository_free(git_repository)
    is native($libname, $apivers)
    is export
    { * }

# # int git_repository_init_ext(git_repository **out, const char *repo_path, git_repository_init_options *opts);
# sub git_repository_init_ext(Pointer[git_repository], Str, Pointer[git_repository_init_options])
#     returns int32
#     is native($libname, $apivers)
#     is export
#     { * }

# # const char * git_repository_path(git_repository *repo);
# sub git_repository_path(git_repository)
#     returns Str         # TODO explicitly-manage
#     is native($libname, $apivers)
#     is export
#     { * }

# # const char * git_repository_workdir(git_repository *repo);
# sub git_repository_workdir(git_repository)
#     returns Str
#     is native($libname, $apivers)
#     is export
#     { * }

# int git_repository_index(git_index **out, git_repository *repo);
sub git_repository_index(git_index is rw, git_repository)
    returns int32
    is native($libname, $apivers)
    is export
    { * }


# class Repository {
#     has $.repository;   # handle

# }



# ### API Section: index

# int git_index_write_tree(git_oid *out, git_index *index);
sub git_index_write_tree(git_oid is rw, git_index)
    returns int32
    is native($libname, $apivers)
    is export
    { * }

# void git_index_free(git_index *index);
sub git_index_free(git_index)
    is native($libname, $apivers)
    is export
    { * }




# ### API Section: signature



# # int git_signature_default(git_signature **out, git_repository *repo);
sub git_signature_default(git_signature is rw, git_repository)
    returns int32
    is native($libname, $apivers)
    is export
    { * }

# # void git_signature_free(git_signature *sig);
sub git_signature_free(git_signature)
    is native($libname, $apivers)
    is export
    { * }




# ### API Section: tree



# int git_tree_lookup(git_tree **out, git_repository *repo, const git_oid *id);
sub git_tree_lookup(git_tree is rw, git_repository, git_oid is rw)     # TODO const for @id?
    returns int32
    is native($libname, $apivers)
    is export
    { * }

# void git_tree_free(git_tree *tree);
sub git_tree_free(git_tree)
    is native($libname, $apivers)
    is export
    { * }




# ### API Section: commit

# int git_commit_create_v(git_oid *id, git_repository *repo, const char *update_ref, const git_signature *author, const git_signature *committer, const char *message_encoding, const char *message, const git_tree *tree, size_t parent_count);
sub git_commit_create_v(git_oid is rw, git_repository, Str, git_signature, git_signature, Str, Str, git_tree, size_t)    # TODO almost everything for explicitly-manage
    returns int32
    is native($libname, $apivers)
    is export
    { * }


# TODO test this with multiple imports
INIT {
    say "init: " ~ git_libgit2_init();
}

END {
    say "end: " ~ git_libgit2_shutdown();
}

say git_libgit2_features();


}
