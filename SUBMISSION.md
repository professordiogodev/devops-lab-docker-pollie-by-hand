# Submission

Fork URL: <!-- paste the URL of your fork here -->

## Files to commit

- [ ] `stack.sh`: the script that builds the whole stack from nothing, committed to the repo
- [ ] `backup.sql`: a `pg_dump` of the Pollie database, committed to the repo

## Questions

Answer in your own words. Where a question asks for output, paste it in a code block.

### Q1. On the default bridge network two containers could not reach each other by name; on your own network they could. Paste both results. What does Docker run to make names work on user-defined networks, and what is the practical consequence for how you connect containers?

**Your answer:**

<!-- replace this line with your answer -->

### Q2. Paste `docker network inspect pw-backend` (the `Containers` part) and the two `nc` results from the web container (to the database and to the API). Why is it good that the web container cannot reach the database, even though nothing is "attacking" it?

**Your answer:**

<!-- replace this line with your answer -->

### Q3. You removed the database container with `docker rm -f pw-db`. Paste what happened to the polls (a) with the named volume and (b) in the experiment without one. What exactly is the difference between a named volume, a bind mount and an anonymous volume, and which of the three did you use for `nginx.conf`, for the database and for the throwaway experiment?

**Your answer:**

<!-- replace this line with your answer -->

### Q4. Why is `pg_dump` the right way to back up a running database, and copying the volume directory the wrong one? Paste the command you used and the first lines of `backup.sql`.

**Your answer:**

<!-- replace this line with your answer -->

### Q5. Why does only the web container publish a port, and what is the difference between `-p 8080:80` and `-p 127.0.0.1:8080:80`? What breaks if the API starts before the database is ready, and what did you do about it?

**Your answer:**

<!-- replace this line with your answer -->

### Q6. Writing `stack.sh` by hand: name three things that were repetitive or fragile. What would you want a tool to do for you instead?

**Your answer:**

<!-- replace this line with your answer -->

### Q7. Paste the output of `./verify.sh`. It must end with **ALL CHECKS PASSED**.

**Your answer:**

<!-- replace this line with your answer -->

### Q8. **Tear down.** Paste the output of `./verify-teardown.sh`. It must end with **TEARDOWN VERIFIED**.

**Your answer:**

<!-- replace this line with your answer -->
