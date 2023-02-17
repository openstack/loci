#!/usr/bin/env python
import os
import sys

customize_path = os.path.join(
    next(p for p in sys.path
         if p and p.endswith('site-packages')),
    "usercustomize.py")

script = """\
import os

def _trueish(name, default=''):
    return os.getenv(name, default).lower() in ['true', '1', 'yes', 'on']

def _configure():
    application_name = os.getenv('PYRO_APP_NAME')
    if not application_name:
        return

    app_subset = os.getenv('PYRO_APP_SUBSET')
    if app_subset:
        import re
        try:
            pattern = re.compile(app_subset)
            if not pattern.search(os.getenv('HOSTNAME')):
                return
        except (ValueError, TypeError, re.error):
            return

    try:
        import pyroscope
    except ImportError:
        return

    tags = os.getenv('PYRO_TAGS')
    if tags:
        tags = dict(s.split("=") for s in tags.split(";"))
    pyroscope.configure(application_name=application_name,
                        server_address=os.getenv('PYRO_URL', 'http://pyroscope:4040'),
                        auth_token=os.getenv('PYRO_AUTH_TOKEN', ''),
                        enable_logging=_trueish('PYRO_ENABLE_LOGGING'),
                        sample_rate=int(os.getenv('PYRO_SAMPLE_RATE', 100)),
                        detect_subprocesses=_trueish('PYRO_DETECT_SUBPROCESSES', 'True'),
                        oncpu=_trueish('PYRO_ONCPU', 'True'),
                        native=_trueish('PYRO_NATIVE'),
                        gil_only=_trueish('PYRO_GIL_ONLY', 'True'),
                        report_pid=_trueish('PYRO_REPORT_PID'),
                        report_thread_id=_trueish('PYRO_REPORT_THREAD_ID'),
                        report_thread_name=_trueish('PYRO_REPORT_THREAD_NAME'),
                        tags=tags)

_configure()
"""


if not os.path.exists(customize_path):
    with open(customize_path, "w") as sc:
        print("Writing to " + customize_path)
        sc.write(script)
        sc.flush()
