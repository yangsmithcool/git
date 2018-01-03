#!/bin/sh

test_description='test git wire-protocol version 2'

TEST_NO_CREATE_REPO=1

. ./test-lib.sh

# Test protocol v2 with 'file://' transport
#
test_expect_success 'create repo to be served by file:// transport' '
	git init file_parent &&
	test_commit -C file_parent one
'

test_expect_success 'list refs with file:// using protocol v2' '
	GIT_TRACE_PACKET=1 git -c protocol.version=2 \
		ls-remote --symref "file://$(pwd)/file_parent" >actual 2>log &&

	# Server responded using protocol v2
	cat log &&
	grep "git< version 2" log &&

	git ls-remote --symref "file://$(pwd)/file_parent" >expect &&
	test_cmp actual expect
'

test_expect_success 'ref advertisment is filtered with ls-remote using protocol v2' '
	GIT_TRACE_PACKET=1 git -c protocol.version=2 \
		ls-remote "file://$(pwd)/file_parent" master 2>log &&

	grep "ref-pattern master" log &&
	! grep "refs/tags/" log
'

test_expect_success 'clone with file:// using protocol v2' '
	GIT_TRACE_PACKET=1 git -c protocol.version=2 \
		clone "file://$(pwd)/file_parent" file_child 2>log &&

	git -C file_child log -1 --format=%s >actual &&
	git -C file_parent log -1 --format=%s >expect &&
	test_cmp expect actual &&

	# Server responded using protocol v1
	grep "clone< version 2" log
'

test_expect_success 'fetch with file:// using protocol v2' '
	test_commit -C file_parent two &&

	GIT_TRACE_PACKET=1 git -C file_child -c protocol.version=2 \
		fetch origin 2>log &&

	git -C file_child log -1 --format=%s origin/master >actual &&
	git -C file_parent log -1 --format=%s >expect &&
	test_cmp expect actual &&

	# Server responded using protocol v1
	grep "fetch< version 2" log
'

test_expect_success 'ref advertisment is filtered during fetch using protocol v2' '
	test_commit -C file_parent three &&

	GIT_TRACE_PACKET=1 git -C file_child -c protocol.version=2 \
		fetch origin master 2>log &&

	git -C file_child log -1 --format=%s origin/master >actual &&
	git -C file_parent log -1 --format=%s >expect &&
	test_cmp expect actual &&

	grep "ref-pattern master" log &&
	! grep "refs/tags/" log
'

test_done
