Most of testcases used in the testplans here assume that a device-uri is
provided in the environment definition, that is, the environment variable
``XNVME_URI`` is set.

Checking the environment variable is done by::

  : "${XNVME_URI:?Must be set and non-empty}"

So, if you see that error. That is why.

Adding to that. The preferred way to assign ``XNVME_URI`` is to set it based on
the value of ``XNVME_BE``, and then control ``XNVME_BE`` from the testplan.

Have a look at the testplans and the reference environment.
