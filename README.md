# Twine

Twine is a command line tool for managing your strings and their translations. These are all stored in a master text file and then Twine uses this file to import and export localization files in a variety of types, including iOS and Mac OS X `.strings` files and Android `.xml` files. This allows individuals and companies to easily share translations across multiple projects, as well as export localization files in any format the user wants.

## Install

### From Source

You can run Twine directly from source. However, it requires [rubyzip][rubyzip] in order to create and read standard zip files.

	$ gem install rubyzip
	$ git clone git://github.com/kimeva/twine.git
	$ cd twine
	$ ./twine --help

Make sure you run the `twine` executable at the root of the project as it properly sets up your Ruby library path. The `bin/twine` executable does not.

## Twine File Format

Twine stores everything in a single file, the Twine data file. The format of this file is a slight variant of the [Git][git] config file format, which itself is based on the old [Windows INI file][INI] format.

The entire file is broken up into two main sections, which are created by placing the section name between two pairs of square brackets. Each grouping section contains N definitions. These definitions start with the key placed within a single pair of square brackets. It then contains a number of key-value pairs, including a comment, a comma-separated list of tags, and all of the translations.

## Plural Formatting

To distinguish plural resources from regular resources, the twine file is separated into two types of sections:

* Uncategorized encompasses all strings that are not pluralized.
* Plural Categories are the rest of the categories, where each section is one plural set.

To illustrate this:

```ini
	[[n_years]]
		[n_years__one]
			en = %d year
			ios = %#@n_years@
		[n_years__other]
			en = %d years
			ios = %#@n_years@

	[[Uncategorized]]
		[hello_world]
			en = Hello World!
		[n_years]
			en = %#@n_years@
```

`n_years` is the section name and the key of the plural.

## The `__` Notation

`n_years__one` uses the double underscores (`__`) to separate the plural value key out. Twine will look for `__` to find the plural value key to format the plurals properly. So the plural will look like this in Android and iOS format:

```xml
	<plurals name="n_years">
		<item quantity="one">%d year</item>
		<item quantity="other">%d years</item>
	</plurals>
```

```xml
	<key>n_years</key>
		<dict>
		<key>NSStringLocalizedFormatKey</key>
		<string>%#@n_years@</string>
		<key>n_years</key>
		<dict>
			<key>NSStringFormatSpecTypeKey</key>
			<string>NSStringPluralRuleType</string>
			<key>NSStringFormatValueTypeKey</key>
			<string>d</string>
			<key>one</key>
			<string>%d year</string>
			<key>other</key>
			<string>%d years</string>
		</dict>
	</dict>
```

## The `ios` Field

Looking closer at our example, another feature to take note of is the `ios` field:

```ini
	[[n_years]]
		[n_years__one]
			en = %d year
			ios = %#@n_years@
		[n_years__other]
			en = %d years
			ios = %#@n_years@

	[[Uncategorized]]
		[hello_world]
			en = Hello World!
		[n_years]
			en = %#@n_years@
```

iOS plural resources have another key for their plural resources called the `NSStringLocalizedFormatKey`. This has a snake cased string surrounded by `%#@key_here@` and this key must be included in the main `Localizable.strings` file with the same key of the entire plural as its key. (ie. `n_years = %#@n_years@;`) This is why `ios = %#@key_here@` was introduced and you'll notice it'll also be a definition under `Uncategorized` because of iOS resource specifications.

### Placeholders

Twine supports [`printf` style placeholders][printf].

### Tags

Tags are used by Twine as a way to only work with a subset of your definitions at any given point in time. Each definition can be assigned zero or more tags which are separated by commas. Tags are optional, though highly recommended. You can get a list of all definitions currently missing tags by executing the [`validate-twine-file`](#validate-twine-file) command with the `--pedantic` option.

When generating a localization file, you can specify which definitions should be included using the `--tags` option. Provide a comma separated list of tags to match all definitions that contain any of the tags (`--tags tag1,tag2` matches all definitions tagged with `tag1` _or_ `tag2`). Provide multiple `--tags` options to match defintions containing all specified tags (`--tags tag1 --tags tag2` matches all definitions tagged with `tag1` _and_ `tag2`). You can match definitions _not_ containing a tag by prefixing the tag with a tilde (`--tags ~tag1` matches all definitions _not_ tagged with `tag1`.). All three options are combinable.

### Whitespace

Whitepace in this file is mostly ignored. If you absolutely need to put spaces at the beginning or end of your translated string, you can wrap the entire string in a pair of `` ` `` characters. If your actual string needs to start *and* end with a grave accent, you can wrap it in another pair of `` ` `` characters. See the example, below.

### Example

```ini
	[[n_windows]]
		[n_windows__one]
			ios = %#@n_windows@
			en = %d window for %s
			zh-HK = %d 窗口 %s
			tags = ios,android,web
		[n_windows__other]
			ios = %#@n_windows@
			en = %d windows for %s
			zh-HK = %d 窗戶 %s
			tags = ios,android,web

	[[Uncategorized]]
		[n_windows]
			en = %d window for %s
			zh-HK = %d 窗口 %s
			comment = 'n' number of windows.
			tags = ios,android
		[GREETINGS_HELLO]
			en = Hello '%s' and '%s'
			zh-HK = '%s' 你好 '%s'
			comment = A friendly greeting.
			tags = ios,android,web
		[GREETINGS_GOOD_AFTERNOON]
			en = Good Afternoon
			zh-HK = 下午好
			comment = A greeting done during the afternoon.
			tags = ios,android,web
```

## Supported Output Formats

Twine currently supports the following output formats:

* [iOS and OS X String Resources][applestrings] (format: apple)
* [Android String Resources][androidstrings] (format: android)
* [JSON] (format: json)

## Usage

	Usage: twine COMMAND TWINE_FILE [INPUT_OR_OUTPUT_PATH] [--lang LANG1,LANG2...] [--tags TAG1,TAG2,TAG3...] [--format FORMAT]
	Example: `twine generate-all-localization-files ./input/strings.txt ./output/web --lang zh-HK,en-SG --tags web --format json --create-folders`

### Commands

#### `generate-localization-file`

This command creates a localization file from the Twine data file. If the output file would not contain any translations, Twine will exit with an error.

	$ twine generate-localization-file /path/to/twine.txt values-ja.xml --tags common,app1
	$ twine generate-localization-file /path/to/twine.txt Localizable.strings --lang ja --tags mytag
	$ twine generate-localization-file /path/to/twine.txt all-english.strings --lang en

#### `generate-all-localization-files`

This command is a convenient way to call [`generate-localization-file`](#generate-localization-file) multiple times. It uses standard conventions to figure out exactly which files to create given a parent directory. For example, if you point it to a parent directory containing `en.lproj`, `fr.lproj`, and `ja.lproj` subdirectories, Twine will create a `Localizable.strings` file of the appropriate language in each of them. However, files that would not contain any translations will not be created; instead warnings will be logged to `stderr`. This is often the command you will want to execute during the build phase of your project.

	$ twine generate-all-localization-files /path/to/twine.txt /path/to/project/locales/directory --tags common,app1

#### `consume-localization-file`

This command slurps all of the translations from a localization file and incorporates the translated strings into the Twine data file. This is a simple way to incorporate any changes made to a single file by one of your translators. It will only identify definitions that already exist in the data file.

	$ twine consume-localization-file /path/to/twine.txt fr.strings
	$ twine consume-localization-file /path/to/twine.txt Localizable.strings --lang ja
	$ twine consume-localization-file /path/to/twine.txt es.xml

#### `consume-all-localization-files`

This command reads in a folder containing many localization files. These files should be in a standard folder hierarchy so that Twine knows the language of each file. When combined with the `--developer-language`, `--consume-comments`, and `--consume-all` flags, this command is a great way to create your initial Twine data file from an existing project. Just make sure that you create a blank Twine data file first!

	$ twine consume-all-localization-files twine.txt Resources/Locales --developer-language en --consume-all --consume-comments

#### `generate-loc-drop`

This command is a convenient way to generate a zip file containing files created by the [`generate-localization-file`](#generate-localization-file) command. If a file would not contain any translated strings, it is skipped and a warning is logged to `stderr`. This command can be used to create a single zip containing a large number of translations in all languages which you can then hand off to your translation team.

	$ twine generate-loc-drop /path/to/twine.txt LocDrop1.zip
	$ twine generate-loc-drop /path/to/twine.txt LocDrop2.zip --lang en,fr,ja,ko --tags common,app1

#### `consume-loc-drop`

This command is a convenient way of taking a zip file and executing the [`consume-localization-file`](#consume-localization-file) command on each file within the archive. It is most often used to incorporate all of the changes made by the translation team after they have completed work on a localization drop.

	$ twine consume-loc-drop /path/to/twine.txt LocDrop2.zip

#### `validate-twine-file`

This command validates that the Twine data file can be parsed, contains no duplicate keys, and that no key contains invalid characters. It will exit with a non-zero status code if any of those criteria are not met.

	$ twine validate-twine-file /path/to/twine.txt

## Creating Your First Twine Data File

The easiest way to create your first Twine data file is to run the [`consume-all-localization-files`](#consume-all-localization-files) command. The one caveat is to first create a blank file to use as your starting point. Then, just point the `consume-all-localization-files` command at a directory in your project containing all of your localization files.

	$ touch twine.txt
	$ twine consume-all-localization-files twine.txt Resources/Locales --developer-language en --consume-all --consume-comments

### Other Arguments

| Command | Description |
| --- | --- |
| `--[no-]create-folders` | When running the generate-all-localization-files command, this flag may be used to create output folders for all languages if they  don't exist yet. As a result all languages will be exported, not only the ones where an output folder already exists.|

## Extending Twine

If there's a format Twine does not yet support and you're keen to change that, check out the [documentation](documentation/formatters.md).

## Contributors

Many thanks to all of the contributors to the Twine project, including:

* [Blake Watters](https://github.com/blakewatters)
* [bootstraponline](https://github.com/bootstraponline)
* [Ishitoya Kentaro](https://github.com/kent013)
* [Joseph Earl](https://github.com/JosephEarl)
* [Kevin Everets](https://github.com/keverets)
* [Kevin Wood](https://github.com/kwood)
* [Mohammad Hejazi](https://github.com/MohammadHejazi)
* [Robert Guo](http://www.robertguo.me/)
* [Sebastian Ludwig](https://github.com/sebastianludwig)
* [Sergey Pisarchik](https://github.com/SergeyPisarchik)
* [Shai Shamir](https://github.com/pichirichi)
* [500px](https://github.com/500px)


[rubyzip]: http://rubygems.org/gems/rubyzip
[git]: http://git-scm.org/
[INI]: http://en.wikipedia.org/wiki/INI_file
[applestrings]: http://developer.apple.com/documentation/Cocoa/Conceptual/LoadingResources/Strings/Strings.html
[androidstrings]: http://developer.android.com/guide/topics/resources/string-resource.html
[gettextpo]: http://www.gnu.org/savannah-checkouts/gnu/gettext/manual/html_node/PO-Files.html
[jquerylocalize]: https://github.com/coderifous/jquery-localize
[djangopo]: https://docs.djangoproject.com/en/dev/topics/i18n/translation/
[tizen]: https://developer.tizen.org/documentation/articles/localization
[printf]: https://en.wikipedia.org/wiki/Printf_format_string
