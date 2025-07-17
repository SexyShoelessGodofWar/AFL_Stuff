# AFL_Stuff
If you've ever dived into the world of fuzzing with AFL++, you know it's thrilling when it works, frustrating when it crashes, but rewarding in the end. I'm no stranger to this process; I've spent countless late nights coaxing AFL++ to find vulnerabilities, and along the way, I've picked up a couple of tricks that make the whole process less of a headache and more efficient. I'll aim to add here things that might be useful and update as regularly as I can be bothered.


# Parallelism
Parallelism lets you distribute the workload across cores and while it shoudl be expected it's a fucking great feature. Once I started using it, I think the world of fuzzing just became vastly more accessible. AFL++'s master-slave setup syncs finds in real-time. But more instances can overload your machine if not managed well.

I've learned that using every last core can make your system overload. That's why I use the N-1 rule, where N is your total CPU cores. Leave one core free for the OS. But the reality is, you should squeeze every goddamn core out of a system you can.  I never fuzz with anything less than 32 cores, and when this is combined with a good harness and other optmisation techniques 

I've uploaded a script that will help with this.


# Persistent Mode - Use it
In standard fuzzing, AFL++ forks and executes your target for every input, which works for slow binaries but slows down quick ones. Persistent mode loops the target in the same process, skipping the overhead, and can achieve much faster speeds.

Always use persistent mode when possible. It requires some code changes in your target. Add AFL++ hooks to your fuzzing logic, but it's relatively straight forward and the performance increase is *significant*

# Harness
Well, it's pretty hard to tell you how to write a harness, but this should be good too. And the truth is, a good harness can make or break any fuzzing efforts. I may well start publishign some of my harnesses on here, but there's some art and pre-work to go into these. For libraries, it's very straight forward, but when dealing with blackbox binaries, a good harness relies on good reverse engineering!

# RamDisks

TODO

#
