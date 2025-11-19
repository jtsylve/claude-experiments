---
template_name: document-qa
category: analysis
keywords: [document, question, answer, cite, reference, quote, source, extract]
complexity: intermediate
variables: [DOCUMENT, QUESTION]
version: 1.0
description: Answer questions about documents with cited references
---

You will answer a question about a document with cited references.

<document>
{$DOCUMENT}
</document>

Question: {$QUESTION}

Process:
1. Find exact quotes from the document most relevant to the question
2. Print quotes in numbered order (or "No relevant quotes" if none exist)
3. Answer the question, referencing quotes by bracketed numbers at end of relevant sentences

Format your response exactly as shown:

<example>
<Relevant Quotes>
<Quote> [1] "Company X reported revenue of $12 million in 2021." </Quote>
<Quote> [2] "Almost 90% of revenue came from widget sales, with gadget sales making up the remaining 10%." </Quote>
</Relevant Quotes>
<Answer>
[1] Company X earned $12 million. [2] Almost 90% of it was from widget sales.
</Answer>
</example>

Do not include or reference quoted content verbatim in the answer. Don't say "According to Quote [1]". If the question cannot be answered by the document, say so.

Answer immediately without preamble.
