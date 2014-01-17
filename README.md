iPDF
====

A library to generate various forms of PDF documents. There are a lot of PDF 'viewers' out there, some free and some commercial ones (which are pretty solid, PSPDFKit specifically), but I couldn't come accross any good 'generator'. The objective of iPDF is to make PDF generation as fun as writing a web page (WYSIWYG), but at the same time truely dynamic and logic bound; with solid templating support. iPDF uses Mustache and HTML as the markup languages for templating and CSS for styling. iPDF also has a data source architecture and configurable paging, to create truely dynamic documents. 'Partials' can be put together based on some logic to build a document.

A iPDFDocument is structured as such:


*->documentHeader
	*-> pageHeader
		*-> pageContent
	*-> pageFooter
*->documentFooter

You can easily plug into each section with the use of "Partials", you can also eliminate a section completely.




TODOs:
* Code refactoring
* More Documentation
* More features
