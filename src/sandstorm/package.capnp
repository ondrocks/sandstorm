# Sandstorm - Personal Cloud Sandbox
# Copyright (c) 2014 Sandstorm Development Group, Inc. and contributors
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

@0xdf9bc20172856a3a;
# This file contains schemas relevant to the Sandstorm package format.  See also the `spk` tool.

$import "/capnp/c++.capnp".namespace("sandstorm::spk");

using Util = import "util.capnp";
using Grain = import "grain.capnp";

struct PackageDefinition {
  id @0 :Text;
  # The app's ID string. This is actually an encoding of the app's public key generated by the spk
  # tool, and looks something like "h37dm17aa89yrd8zuqpdn36p6zntumtv08fjpu8a8zrte7q1cn60".
  #
  # Normally, `spk init` will fill this in for you. You can use `spk keygen` to generate a new ID
  # if needed. The private key corresponding to each ID is stored in a keyring outside your project
  # directory; see `spk help` for more on this.
  #
  # Note that you can specify an alternative ID to `spk pack` with the `-i` flag. This makes sense
  # when you are doing an unofficial build of an app and don't want to use (or don't have access
  # to) the app's real private key.

  manifest @1 :Manifest;
  # Manifest to write as the package's `sandstorm_manifest`.  If null, then `sandstorm-manifest`
  # should appear in the file list.

  sourceMap @2 :SourceMap;
  # Indicates where to search for file to include in the package.

  fileList @3 :Text;
  # Name of a file which itself contains a list of files, one per line, that should be included
  # in the package. Each file should be specified according to its location in the package; the
  # source file will be found by mapping this through `sourceMap`. Each name should be canonical
  # (no ".", "..", or consecutive slashes) and should NOT start with '/'.
  #
  # The file list is automatically generated by `spk dev` based on watching what files are opened
  # by the actual running server. On subsequent runs, new files will be added, but files will never
  # be removed from the list. To reset the list, simply delete it and run `spk dev` again.

  alwaysInclude @4 :List(Text);
  # Files and directories that should always be included in the package whether or not they are
  # in the file named by `fileList`. If you name a directory here, its entire contents will be
  # included recursively (this is not the case in `fileList`). Use this list to name files that
  # wouldn't automatically be included, because for whatever reason the server does not actually
  # open them when running in dev mode. This could include runtime dependencies that are too
  # difficult to test fully, or perhaps a readme file or copyright notice that you want people to
  # see if they unpack your package manually.

  bridgeConfig @5 :BridgeConfig;
  # Configuration variables for apps that use sandstorm-http-bridge.
}

struct Manifest {
  # This manifest file defines an application.  The file `sandstorm-manifest` at the root of the
  # application's `.spk` package contains a serialized (binary) instance of `Manifest`.
  #
  # TODO(soon):  Maybe this should be renamed.  A "manifest" is a list of contents, but this
  #   structure doesn't contain a list at all; it contains information on how to use the contents.

  const sizeLimitInWords :UInt64 = 1048576;
  # The maximum size of the Manifest is 8MB (1M words). This limit is enforced in many places.

  appTitle @7 :Util.LocalizedText;
  # The name of this app as it should be displayed to the user.

  appVersion @4 :UInt32;
  # Among app packages with the same app ID (i.e. the same `publicKey`), `version` is used to
  # decide which packages represent newer vs. older versions of the app.  The sole purpose of this
  # number is to decide whether one package is newer than another; it is not normally displayed to
  # the user.  This number need not have anything to do with the "marketing version" of your app.

  minUpgradableAppVersion @5 :UInt32;
  # The minimum version of the app which can be safely replaced by this app package without data
  # loss.  This might be non-zero if the app's data store format changed drastically in the past
  # and the app is no longer able to read the old format.

  appMarketingVersion @6 :Util.LocalizedText;
  # Human-readable presentation of the app version, e.g. "2.9.17".  This will be displayed to the
  # user to distinguish versions.  It _should_ match the way you identify versions of your app to
  # users in documentation and marketing.

  minApiVersion @0 :UInt32;
  maxApiVersion @1 :UInt32;
  # Min and max API versions against which this app is known to work.  `minApiVersion` primarily
  # exists to warn the user if their instance is too old.  If the sandstorm instance is newer than
  # `maxApiVersion`, it may engage backwards-compatibility hacks and hide features introduced in
  # newer versions.

  metadata @8 :Metadata;
  # Stuff that's not important to actually executing the app, but important to how the app is
  # presented to the user in the Sandstorm UI and app marketplace.

  struct Command {
    # Description of a command to execute.
    #
    # Note that commands specified this way are NOT interpreted by a shell.  If you want shell
    # expansion, you must include a shell binary in your app and invoke it to interpret the
    # command.

    argv @1 :List(Text);
    # Argument list, with the program name as argv[0].

    environ @2 :List(Util.KeyValue);
    # Environment variables to set.  The environment will be completely empty other than what you
    # define here.

    deprecatedExecutablePath @0 :Text;
    # (Obsolete) If specified, will be inserted at the beginning of argv. This is now redundant
    # because you should just specify the program as argv[0]. To be clear, this does not and did
    # never provide a way to make argv[0] contain something other than the executable name, as
    # you can technically do with the `exec` system call.
  }

  struct Action {
    input :union {
      none @0 :Void;
      # This action creates a new grain with no input.

      capability @1 :List(Grain.PowerboxDescriptor);
      # This action creates a new grain from a powerbox offer. When a capability matching the query
      # is offered to the user (e.g. by another application calling SessionContext.offer()), this
      # action will be listed as one of the things the user can do with it.
      #
      # On startup, the platform will call create the first session with
      # `UiView.newOfferSession()`.
    }

    command @2 :Command;
    # Command to execute (in a newly-allocated grain) to run this action.

    title @3 :Util.LocalizedText;
    # Title of this action, to display in the action selector.

    description @4 :Util.LocalizedText;
    # Description of this action, suitable for help text.
  }

  actions @2 :List(Action);
  # Actions which this grain offers.

  continueCommand @3 :Command;
  # Command to run to restart an already-created grain.
}

struct SourceMap {
  # Defines where to find files that need to be included in a package.  This is usually combined
  # with a list of files that the package is expected to contain in order to compile a package.
  # The list of files may come from using "spk dev" to

  searchPath @0 :List(Mapping);
  # List of directories to map into the package.

  struct Mapping {
    # Describes a directory to be mapped into the package.

    packagePath @0 :Text;
    # Path where this directory should be mapped into the package.  Must be a canonical file name
    # (no "." nor "..") and must not start with '/'. Omit to map to the package root directory.

    sourcePath @1 :Text;
    # Path on the local system where this directory may be found.  Relative paths are interpreted
    # relative to the location of the package definition file.

    hidePaths @2 :List(Text);
    # Names of files or subdirectories within the directory which should be hidden when mapping
    # this path into the spk.  Use only canonical paths here -- i.e. do not use ".", "..", or
    # multiple consecutive slashes.  Do not use a leading slash.
  }
}

struct BridgeConfig {
  # Configuration variables specific to apps that are using sandstorm-http-bridge. This includes
  # things that need to be communicated to the bridge process before the app starts up, such as
  # permissions.

  viewInfo @0 :Grain.UiView.ViewInfo;
  # What to return from the UiView's getViewInfo(). This structure defines, among other things, the
  # list of sharable permissions and roles that apply to this app. See grain.capnp for more details.
  #
  # When a request comes in from the user, sandstorm-http-bridge will set the
  # X-Sandstorm-Permissions header to a comma-delimited list of permission names corresponding to
  # the user's permissions.

  apiPath @1 :Text;
  # This variable's purpose is two-fold:
  # First, if it's set to anything non-empty, it will enable ApiSessions in sandstorm-http-bridge.
  # This means calling newSession with an ApiSession type id will return an ApiSession correctly.
  # Second, as the name implies, this specifies the path to the API in an app. For example, if
  # your API endpoints always begin with /v1/api/, then you would provide that path. This path will
  # always be prepended for you, and clients accessing the API will not have to provide it. This
  # also has the effect of limiting your clients to only accessing endpoints under that path you
  # provide. It should always end in a trailing '/'.
  # "/" is a valid value, and will give clients access to all paths.
}

struct Metadata {
  # Data which is not needed specifically to execute the app, but is useful for purposes like
  # marketing and display.
  #
  # Technically, appMarketingVersion and appTitle belong in this category, but they were defined
  # before MarketData became a thing.
  #
  # NOTE: Any changes here which add new blobs may require updating the front-end so that it
  #   correctly extracts those blobs into separate assets on install.

  icons :group {
    # Various icons to represent the app in various contexts.
    #
    # Each context is associated with a List(Icon). This list contains versions of the same image
    # in varying sizes and formats. When the icon is used, the optimal icon image will be chosen
    # from the list based on the context where it is to be displayed, possibly taking into account
    # parameters like size, display pixel density, and browser image format support.

    main @0 :List(Icon);
    # The icon which represents the app itself, such as in an "app grid" view showing the user
    # all of their apps.

    grain @1 :List(Icon);
    # An icon which represents one grain created with this app. If omitted, `main` will be used.

    banner @2 :List(Icon);
    # A big icon used when displaying this app in e.g. an app market. Generally this icon should be
    # bigger and "flashier", though still square. If omitted, `main` will be used.
  }

  struct Icon {
    # Represents one icon image.

    width @0 :UInt32;
    # The width (and height) of this icon image in pixels. This is only relevant for raster icons
    # (e.g. PNG).

    union {
      unknown @1 :Void;
      # Unknown file format.

      png @2 :Data;
      # PNG-encoded image data.

      svg @3 :Text;
      # SVG image data. Note that SVG is usually preferred over PNG if it is available and the use
      # case can handle it.
    }
  }

  website @3 :Text;
  # URL of the app's main web site.

  codeUrl @4 :Text;
  # URL of the app's source code repository, e.g. a Github URL.
  #
  # This field is required if the app's license requires redistributing code (such as the GPL),
  # but is optional otherwise.

  license :group {
    # How is this app licensed?
    #
    # Example usage for open source licenses:
    #
    #     license = (openSource = apache2, notices = embed "notices.txt"),
    #
    # Example usage for proprietary licenses:
    #
    #     license = (proprietary = embed "license.txt", notices = embed "notices.txt"),

    union {
      none @5 :Void;
      # No license. Default copyright rules apply; e.g. redistribution is prohibited. See:
      #     http://choosealicense.com/no-license/
      #
      # "None" does NOT mean "public domain". Since public domain is not recognized in all
      # jurisdictions, we recommend that Sandstorm apps choose an open source license like MIT
      # or Apache 2 rather than use public domain.

      openSource @6 :OpenSourceLicense;
      # Indicates an OSI-approved open source license.
      #
      # If you choose such a license, the license title will be displayed with your app on the app
      # market, and users who specify they want to see only open source apps will see your app.

      proprietary @7 :Util.LocalizedText;
      # Full text of a non-OSI-approved license.
      #
      # Sandstorm will display the license to the user and ask them to agree before the app is
      # installed. If your license does not require such approval -- because it does not add any
      # restrictions beyond default copyright protections -- consider whether it would make sense
      # to use `none` instead; this will avoid prompting the user.

      publicDomain @8 :Util.LocalizedText;
      # Indicates that the app is placed in the public domain; you place absolutely no restrictions
      # on its use or distribution. The text is your public domain dedication statement. Please
      # note that public domain is not recognized in all jurisdictions, therefore using public
      # domain is widely considered risky. The Open Source Initiative recommends using a permissive
      # license like MIT's rather than public domain. unlicense.org provides resources to help you
      # use public domain; it is highly recommended that you read it before using this.
    }

    notices @9 :Util.LocalizedText;
    # Contains any third-party copyright notices that the app is required to display, for example
    # due to use of third-party open source libraries.
  }

  categories @10 :List(UInt64);
  # List of category IDs under which this app should be classified. Categories are things
  # like "productivity" or "dev tools". Each category ID is generated using `capnp id`. Note that
  # although you can generate your own category IDs, an app market will only recognize a specific
  # set of IDs.
  #
  # TODO(soon): Figure out where we will define the available category IDs. Should we put a basic
  #   list directly in this file?

  author :group {
    # Fields relating to the author of this app.
    #
    # The "author" might be a human, but could also be a company, or a pseudo-identity created to
    # represent the app itself.
    #
    # It is extremely important to users that they be able to verify the author's identity in a way
    # that is not susceptible to spoofing or forgery. Therefore, we *only* identify the author by
    # PGP key. Various PGP infrastructure exists which can be used to determine the author's
    # identity based on their PGP key. For exmaple, Keybase.io has done a really good job of
    # connecting PGP keys to other Internet identities in a verifiable way.

    contactEmail @11 :Text;
    # Email address to contact for any issues with this app. This includes end-user support
    # requests as well as app store administrator requests, so it is very important that this be a
    # valid address with someone paying attention to it.

    pgpSignature @12 :Data;
    # PGP signature attesting responsibility for the app ID. This is a binary-format detached
    # signature of the following ASCII message (not including the quotes, no newlines, and
    # replacing <app-id> with the standard base-32 text format of the app's ID):
    #
    # "I am the author of the Sandstorm.io app with the following ID: <app-id>"
    #
    # Keep in mind that Sandstorm app IDs are also ed25519 public keys, and that every app package
    # is signed by the private key corresponding to its app ID. Therefore this PGP signature forms
    # a chain of trust that can be used to verify each app package.
    #
    # Notice that the signature asserts authorship of all versions of the app, including possible
    # future version, even if maintainership is transferred to a new author (and the new author
    # receives the app private key). This is intentional: When users use the "auto-update" feature,
    # the are making the decision to automatically trust all future versions of the app without
    # re-verifying the author's identity. If you wish to transfer maintainership of your app but
    # you do not trust the new maintainer with the power to publish new packages under your
    # identity, then you should not give the new maintainer the app's private key; you should force
    # them to create a new key. Sandstorm will not auto-update users to the new version without,
    # at the very least, confirming their approval of the change in authorship.

    pgpPublicKey @13 :Data;
    # The public key used to create `pgpSignature`, in binary format, e.g. as output by
    # `gpg --export <email>`. This is included here, rather than looked up from a keyserver, so
    # that a package signature can be verified down to a key fingerprint in isolation.
  }

  description @14 :Util.LocalizedText;
  # The app's description description in Github-flavored Markdown format, to be displayed e.g.
  # in an app store. Note that the Markdown is not permitted to cotnain HTML nor image tags (but
  # you can include a list of screenshots separately).

  shortDescription @15 :Util.LocalizedText;
  # A one-line description, possibly displayed in a directory of apps. If not provided, this will
  # be generated algorithmically from `description` by taking all text up to the first period.
  # Use only plain text here, not Markdown.

  screenshots @16 :List(Screenshot);
  # Screenshots to use for marketing purposes.

  struct Screenshot {
    width @0 :UInt32;
    height @1 :UInt32;
    # Width and height of the screenshot in "device-independent pixels". The actual width and
    # height of the image is in the image data, but this width and height is used to decide how
    # much to scale the image for it to "look right". Typically, a screenshot taken on a high-DPI
    # display should specify this width and height as half of the actual image width and height.
    #
    # The market is under no obligation to display images with any particular size; these are just
    # hints.

    union {
      unknown @2 :Void;
      # Unknown file format.

      png @3 :Data;
      # PNG-encoded image data. Usually preferred for screenshots.

      jpeg @4 :Data;
      # JPEG-encoded image data. Preferred for screenshots that contain photographs or the like.
    }
  }

  changeLog @17 :Util.LocalizedText;
  # Documents the history of changes in Github-flavored markdown format (with the same restrictions
  # as govern `description`). We recommend formatting this with an H1 heading for each version
  # followed by a bullet list of changes.
}

struct OsiLicenseInfo {
  id @0 :Text;
  # The file name of the license at opensource.org, i.e. such that the URL can be constructed as:
  #     http://opensource.org/licenses/<id>

  title @1 :Text;
  # Display title for app market. E.g. "Apache License 2.0".

  requireSource @2 :Bool = false;
  # Whether or not you are required to provide a `codeUrl` when specifying this license.
}

annotation osiInfo(enumerant) :OsiLicenseInfo;
# Annotation applied to each item in the OpenSourceLicense enum.

enum OpenSourceLicense {
  # Identities an OSI-approved Open Source license. Apps which claim to be "open source" must use
  # one of these licenses.

  invalid @0;  # Sentinel value; do not choose this.

  # Recommended licenses, especially for new code. These four licenses cover the spectrum of open
  # source license mechanics and are widely recognized and understood.
  mit        @1 $osiInfo(id = "MIT"       , title = "MIT License");
  apache2    @2 $osiInfo(id = "Apache-2.0", title = "Apache License v2");
  gpl3       @3 $osiInfo(id = "GPL-3.0"   , title = "GNU GPL v3", requireSource = true);
  agpl3      @4 $osiInfo(id = "AGPL-3.0"  , title = "GNU AGPL v3", requireSource = true);

  # Other popular general-purpose licenses.
  bsd3Clause @5 $osiInfo(id = "BSD-3-Clause", title = "BSD 3-Clause");
  bsd2Clause @6 $osiInfo(id = "BSD-2-Clause", title = "BSD 2-Clause");
  gpl2       @7 $osiInfo(id = "GPL-2.0"     , title = "GNU GPL v2", requireSource = true);
  lgpl2      @8 $osiInfo(id = "LGPL-2.1"    , title = "GNU LGPL v2.1", requireSource = true);
  lgpl3      @9 $osiInfo(id = "LGPL-3.0"    , title = "GNU LGPL v3", requireSource = true);
  isc       @10 $osiInfo(id = "ISC"         , title = "ISC License");

  # Popular licenses associated with specific languages.
  artistic2 @11 $osiInfo(id = "Artistic-2.0", title = "Artistic License v2");
  python2   @12 $osiInfo(id = "Python-2.0"  , title = "Python License v2");
  php3      @13 $osiInfo(id = "PHP-3.0"     , title = "PHP License v3");

  # Popular licenses associated with specific projects or companies.
  mpl2      @14 $osiInfo(id = "MPL-2.0" , title = "Mozilla Public License v2", requireSource = true);
  cddl      @15 $osiInfo(id = "CDDL-1.0", title = "CDDL", requireSource = true);
  epl       @16 $osiInfo(id = "EPL-1.0" , title = "Eclipse Public License", requireSource = true);

  # Is your preferred license not on the list? We are happy to add any OSI-approved license; that
  # is, anything on this page:
  #     http://opensource.org/licenses/alphabetical
  #
  # Feel free to send a pull request adding yours.
}

# ==============================================================================
# Below this point is not interesting to app developers.
#
# TODO(cleanup): Maybe move elsewhere?

struct KeyFile {
  # A public/private key pair, as generated by libsodium's crypto_sign_keypair.
  #
  # The keyring maintained by the spk tool contains a sequence of these.
  #
  # TODO(someday):  Integrate with desktop environment's keychain for more secure storage.

  publicKey @0 :Data;
  privateKey @1 :Data;
}

const magicNumber :Data = "\x8f\xc6\xcd\xef\x45\x1a\xea\x96";
# A sandstorm package is a file composed of two messages: a `Signature` and an `Archive`.
# Additionally, the whole file is XZ-compressed on top of that, and the XZ data is prefixed with
# `magicNumber`.  (If a future version of the package format breaks compatibility, the magic number
# will change.)

struct Signature {
  # Contains a cryptographic signature of the `Archive` part of the package, along with the public
  # key used to verify that signature.  The public key itself is the application ID, thus all
  # packages signed with the same key will be considered to be different versions of the same app.

  publicKey @0 :Data;
  # A libsodium crypto_sign public key.
  #
  # libsodium signing public keys are 32 bytes.  The application's ID is simply a textual
  # representation of this key.

  signature @1 :Data;
  # libsodium crypto_sign signature of the crypto_hash of the `Archive` part of the package
  # (i.e. the package file minus the header).
}

struct Archive {
  # A tree of files.  Used to represent the package contents.

  files @0 :List(File);

  struct File {
    name @0 :Text;
    # Name of the file.
    #
    # Must not contain forward slashes nor NUL characters.  Must not be "." nor "..".  Must not
    # be the same as any other file in the directory.

    lastModificationTimeNs @5 :Int64;
    # Modification timestamp to apply to the file after unpack. Measured in nanoseconds.

    union {
      regular @1 :Data;
      # Content of a regular file.

      executable @2 :Data;
      # Content of an executable.

      symlink @3 :Text;
      # Symbolic link path.  The link will be interpreted in the context of the sandbox, where the
      # archive itself mounted as the root directory.

      directory @4 :List(File);
      # A subdirectory containing a list of files.
    }
  }
}
