This integration will create a comment in Aha! each time a feature or 
requirement is referenced in a [Github](http://www.github.com/) commit message.

Installation
------------

1. On the _Settings_ tab of the Github repository, open the _Service Hooks_
  section.
2. Use the _WebHook URLs_ service hook. 
3. Paste the URL from _Hook URL_ section below.
4. Enable this integration below.

Usage
-----

Each commit message to the Github repository will be processed. If the
commit message contains the reference from an Aha! feature or requirement
then the commit message will be added as a comment to the feature or
requirement. The reference can be anywhere in the commit message, e.g. a
commit message like:

    Corrected typo, fixes APP-343.
    
would add a comment to the feature APP-343.