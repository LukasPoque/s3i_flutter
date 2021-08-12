# Contributing to S3I Flutter

First off, thanks for taking the time to contribute! 🎉👍

Since the S3I and the KWH4.0 projects are very big projects (with not so nice documentation 😉), please consider writing an issue describing your needs and main changes 
you are going to do before you start writing code. There is a good chance something similar is in the pipeline or is not wanted. Furthermore that insures that the other 
developers working on this project knows what is currently under change and nothing is done twice.

## Write new code

When you're writing code please consider the following points:
- Provide a clear description of all public classes/members/function and insure that you name the **Exeptions** the method could throw (exept the common ones like 
OutOfMemoryError, StackOverflowError, etc.).
- Write unit tests for data classes you add and include them in the main test file.
- Provide an example use of your added feature in the example.
- Check your code by running the `flutter test` and `flutter analyze` commands.
- Format all files by running `dart format`.
- Update the README if your feature is something new and adds functionality which is usefull for others.

Now you can open a pull request with a clear title and description against the master branch. In the best case you provide a litte changelog in this PR too.
