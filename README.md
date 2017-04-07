## Word Template
This package provides a binary executable to generate word from 
templates and a wrapper object _WordTemplate_ to use it in PHP.
The binary is compiled from c++, which uses the 
[DocxFactory](http://docxfactory.com/) third party library.

### Requirements
The usage relies on a system executable. This means that certain
libraries are required.
- **GCC v5+** - by installing gcc you should have most of these
libraries available
- **libstdc++ 6.0.21** - in certain cases you might have issues 
(like on centos); the problem you might have is with this lib
which needs to be configured manually 
([download](https://drive.google.com/file/d/0B7S255p3kFXNNTIzU2thRlZmYVE/edit))
- **PHP NTS** (Non-Thread-Safe) - this is required because for some
reason the thread safe is not allowed to execute the binary

### Installation
```
composer require archfz/word-template:1.3.x-dev
```
**Note:** require with the specified version, otherwise not the
'package' branch will be used. This branch is better as it does
not include all the c++ source files and libraries that are not
required for functionality.

### Usage
First you need to create a template word document. This must be 
**.docx**. 

In it you create placeholders with braces like the
following: **{placeholder}**. 

You can also bookmark things that you select and then these 
elements will be cloneable. For example bookmark the upper 
placeholder and name it '**myplaceholder**'.

In case of the above described word template you can do the 
following:
```php
use archfz/Word/WordTemplate

$template = new WordTemplate('test.docx');

$template->paste('myplaceholder');
$template->setValue('placeholder', 'Put one here');

$template->paste('myplaceholder');
$template->setValue('placeholder', 'Put another different');

$template->compile();
```
Which will produce a **test_compiled.docx** with two lines:

```
Put one here
Put another different
```

### Contribute
To better understand or to extend functionality you can 
[learn more here](http://docxfactory.com/download/128/).