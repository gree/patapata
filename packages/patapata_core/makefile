.PHONY: coverage
coverage:
	flutter test --coverage --dart-define=IS_TEST=true
	genhtml coverage/lcov.info -o coverage/html
	open coverage/html/index.html