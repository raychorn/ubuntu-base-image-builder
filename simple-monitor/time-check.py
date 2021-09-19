import os
import datetime

TEST_SLACK_TIME = int(os.environ.get('TEST_SLACK_TIME', '0'))
assert isinstance(TEST_SLACK_TIME, int) and (TEST_SLACK_TIME >= 0) and (TEST_SLACK_TIME <= 59), 'TEST_SLACK_TIME is not set in {}'.format(fp_env)

now = datetime.datetime.now()
current_time = (now.minute * 60) + now.second
current_time_secs = (now.hour * 3600) + (now.minute * 60) + now.second
expected_secs_since_last_checkin = 3600

LAST_SLACK_TIME_CHECKIN = int(os.environ.get('LAST_SLACK_TIME_CHECKIN', str(current_time_secs)))
if (current_time == TEST_SLACK_TIME) or ((current_time_secs - LAST_SLACK_TIME_CHECKIN) >= expected_secs_since_last_checkin):
    if ((current_time_secs - LAST_SLACK_TIME_CHECKIN) >= expected_secs_since_last_checkin):
        os.environ['LAST_SLACK_TIME_CHECKIN'] = str(current_time_secs)
