/*
 * gcpassesfix-run - tiny setuid-root launcher for the GCPassesFix prefs bundle.
 *
 * The Settings bundle runs as the unprivileged "mobile" user, but the fix
 * (clearing root-owned Game Center state, staging the certificate profile,
 * rebooting) needs root. This helper is installed setuid root and does nothing
 * but exec /usr/bin/gcpassesfix with one of a fixed set of safe verbs. It
 * accepts no arbitrary arguments and no paths, so it cannot run anything else.
 */

#include <stdio.h>
#include <string.h>
#include <unistd.h>

static const char *allowed[] = { "status", "certs", "reset", "restore", "reboot", NULL };

int main(int argc, char **argv) {
	if (argc != 2) {
		fprintf(stderr, "usage: gcpassesfix-run <status|certs|reset|restore|reboot>\n");
		return 2;
	}

	setuid(0);
	setgid(0);

	for (const char **v = allowed; *v; v++) {
		if (strcmp(argv[1], *v) == 0) {
			char *args[] = { "/usr/bin/gcpassesfix", (char *)*v, NULL };
			execv(args[0], args);
			fprintf(stderr, "could not run /usr/bin/gcpassesfix\n");
			return 1;
		}
	}

	fprintf(stderr, "unknown command\n");
	return 2;
}
