STEP 0, MANDATORY, BEFORE ANY CODE: for every business rule or concept you are about to implement or change, search the codebase for an existing owner (grep the domain words, the types, the function and class names, every call site). Write the result first, as a section 'Existing owners found' in your report (rule -> existing class/function to reuse or extend, or 'none: new owner X because Y'), and commit it before writing logic. Never create a second implementation of a rule. Then proceed.

Performance by design is binding: keep evaluation linear in the horizon and the number of cells (each result computed once and stored), no recursion that re-evaluates shared results or grows with the horizon, bounded memory.

