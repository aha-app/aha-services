The Desk.com integration allows users in Desk.com to create ideas in Aha! from Desk.com cases. You can also link existing ideas to cases. 

To use the Desk.com integration you must:

* Have at least the Contributor role for the products that you want to submit ideas to.
* Have the administrator role in your Aha! account.
* Have the administrator role in your Desk.com account.
* Use the Desk.com Next Gen Agent layout.

## Configuration

First create the integration in Aha!

* Choose the ideas portal you will use for the integration
* Select _Create ideas using customer name_ if you want ideas to be created using the case submitter
* Enter your Desk.com URL
* Click _Authenticate_ and enter your Desk.com login credentials (user must be an administrator in Desk.com)
* Click _Add Integration_ URL
  * This will create an Integration URL within Desk.com for the Aha! integration 
* In Desk.com, go to Admin -> Cases -> Integration URLs
* Open the Aha! Integration URL and copy the shared key
* In Aha!, paste the shared key into the Shared key field in the integration setup
* Enable the integration

Next add the integration into the Desk.com case layout

From the Desk.com admin dashboard:

* Navigate to Cases, then in the left sidebar click Cases -> Next Gen Case Layouts
* Click _Add Case Layout_
* Expand the Integrations panel and drag the Aha! Integration (canvas) into the desired position on the layout
* Click to edit the Aha! Integration (canvas) section and change the height to 500
* Add the layout and make it the default
* Test the integration by opening a case and adding an idea
