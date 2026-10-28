"""Keyword markers in prompt text, used for the descriptive analysis of where designers got stuck.

Each prompt is split into the participant's own words and pasted material (code, tool output,
file listings); the markers below are matched against the participant's own words only, so that
"error" or "FAIL" in a pasted simulator log does not count as frustration. A prompt can carry
several markers. The markers describe what the prompt text says; they are not a measurement of
emotion, effort or difficulty.

  pastes_output   the prompt pastes tool output or says it attaches a log, report or screenshot
  repeated_error  says an earlier problem persists ("still getting", "same error", "didn't work")
  frustration     exasperation or blame ("dude", "I said", "you did not", "stick to")
  urgency         time pressure or insistence ("by today", "very key", "right away", "!!!")
  confusion       says the participant does not understand something
  conceptual      asks what something is, means or why it works that way
  control         redirects or constrains the model ("wait", "don't change", "edit one of those")
  thanks          thanks, praise or relief
A prompt is error-driven when it pastes output that reports a failure or a violation, or carries
the repeated_error marker; a stuck loop is three or more consecutive error-driven prompts in one
team's log for one phase.
"""
import re

LOGLINE = re.compile(
    r"(?i)^\s*(?:\[?(?:error|warning|warn|info|fail|failed|pass|ok|note)\]?\s*[:\]]|%(?:error|warning)|traceback"
    r"|assert|vvp\b|iverilog\b|yosys\b|openroad\b|openlane\b|magic\b|netgen\b|klayout\b|make(?:\[\d+\])?:"
    r"|\$ |❯|\S+@\S+:|[\w./-]+\.(?:v|sv|py|log|rpt|json|tcl|ys|sdc|mk)(?::\d+)?\b|\d+(?:\.\d+)?\s*(?:ns|ps|um|mw|uw)\b"
    r"|(?:wns|tns|slack|violat|number of cells|chip area|total cells)|-{5,}|={5,}|\d{2}:\d{2}:\d{2}|0x[0-9a-f]+|\|.*\|)")
CODELINE = re.compile(
    r"^\s*(?:module\b|endmodule|assign\b|always\b|input\b|output\b|wire\b|reg\b|logic\b|begin\b|end\b|if\s*\(|else\b"
    r"|case\b|def |import |from \w+ import|await |@cocotb|#include|//|/\*|\*/|[{}\[\]();]|\"[\w_]+\"\s*:|\w+\s*<=|\w+\s*=\s*[\w'{(]"
    r"|`(?:define|include|default_nettype|timescale))")
PASTE_NOTE = re.compile(r"(?i)\((?:pasted|attached|uploaded)|\[(?:pasted|screenshot|uploaded|attached|image)|"
                        r"\[[^\]\n]{0,40}\b(?:result|output|log|report|error|trace)s?\b|"
                        r"here (?:is|are) (?:the|my) (?:log|output|error|result|report|violation)s?|"
                        r"(?:this|the following) (?:log|output|error)s?\b|!\[[^\]]*\]\(")
FAILWORD = re.compile(r"(?i)\b(?:error|errors|fail|failed|fails|failing|failure|violation|violations|violated|mismatch"
                      r"|exception|traceback|not found|undefined|cannot|can't|unable|negative slack|timing not met)\b")
# zero counts ("FAIL=0", "0 violations", "no errors") report success, not a failure
ZERO = re.compile(r"(?i)\b(?:fail(?:ed|ures?)?|errors?|violations?|warnings?)\s*[:=]?\s*0\b"
                  r"|\b0\s+(?:errors?|violations?|failures?|failed|warnings?)\b|\bno (?:errors?|violations?|failures?)\b")
LOGCAPS = re.compile(r"\b(?:FAILED|PASSED|ERROR|WARNING|FAIL|PASS)\b|VCD info|Expected:|Got:")

MARKERS = {
    "repeated_error": re.compile(
        r"(?i)\bstill (?:get|getting|got|fail|failing|fails|failed|not|no|the same|same|seeing|showing"
        r"|broken|wrong|error|errors|issue|issues|stuck|a problem)\b"
        r"|\bstill (?:have|has|having|see|there)\b[^.?!\n]{0,25}\b(?:error|issue|problem|violation|fail|warning|bug)\w*"
        r"|\bbeen (?:running|trying|stuck|fighting|debugging)\b|\biteration \d{2,}\b"
        r"|\b(?:\d{2,}|many|several|multiple) (?:runs|iterations|attempts|tries)\b"
        r"|\bsame (?:error|errors|issue|issues|problem|"
        r"problems|result|results|violation|violations|thing|failure)\b|\b(?:didn'?t|did not|doesn'?t|does not|isn'?t|is not)"
        r" (?:work|working|fix|help|change|pass)\w*\b|\bnot (?:working|fixed|passing)\b|\bkeeps? (?:failing|getting|giving|"
        r"showing|happening)\b|\bpersist\w*\b|\b(?:fail\w*|error\w*|wrong|broke\w*|issue)\b[^.\n]{0,30}\bagain\b"),
    "frustration": re.compile(
        r"(?i)\b(?:dude|ugh|wtf|seriously|come on|frustrat\w*|annoy\w*|you (?:did not|didn'?t|keep|never|forgot"
        r"|missed|are not|aren'?t|broke)|i (?:said|told you|asked you)|not what i (?:asked|said|wanted)|stick to"
        r"|wrong (?:design|file|module|one)|that'?s (?:wrong|not right)|this is wrong|not right|why (?:is|are|does|do|did) (?:it|this|that|they) (?:still|not)|why (?:isn'?t|doesn'?t|won'?t|can'?t))\b"),
    "urgency": re.compile(
        r"(?i)!{3,}|\b(?:asap|urgent\w*|deadline\w*|by today|tonight|hurry|right away|very key|crucial|please,? please|immediately"
        r"|must (?:pass|work)|running out of time|worried|nervous|scared|panic\w*|finish (?:this|it) (?:today|now))\b"),
    "confusion": re.compile(
        r"(?i)\b(?:confus\w*|(?:don'?t|do not|didn'?t|did not) (?:understand|get it|get this|get what|know (?:what|how|why|where))"
        r"|dont (?:understand|get|know)|not sure (?:what|how|why|if|where|whether)|no idea|i'?m lost|n00b|noob|newbie"
        r"|new to (?:this|verilog|hardware|hdl|asic|openlane)|unclear|makes? no sense|even mean|what does .{1,40} mean)\b"),
    "conceptual": re.compile(
        r"(?i)\b(?:what (?:is|are|does|do) (?:a|an|the)? ?[\w\- '\"]{2,40}(?:\?|mean|for)|what'?s the (?:difference|point|purpose)"
        r"|difference between|how does [\w\- ]{2,40} work|why (?:is|are|does|do|would|should) (?:it|this|that|we|a|an|the)"
        r" [^.?!\n]{2,80}\?|explain (?:what|why|how|the)|is it (?:good|bad|better|necessary|possible) )"),
    "control": re.compile(
        r"(?i)^\s*(?:wait|stop|no|nope|don'?t|do not|instead|ignore|hold on)\b|\b(?:i want you to|i need you to|stick to"
        r"|only (?:change|modify|edit|touch|use)|do not (?:change|modify|delete|remove|touch|add)|don'?t (?:change|modify"
        r"|delete|remove|touch|add)|without (?:changing|modifying|removing)|keep (?:my|the existing|all|the original)|retain"
        r"|revert|undo|roll ?back|edit one of those|you are looking at|look at [\w./ ]{1,30} instead|try again)\b"),
    "thanks": re.compile(
        r"(?i)\b(?:thank\w*|thx|great|perfect|awesome|amazing|nice|cool|works now|it works|finally|yay|impressive"
        r"|good job|well done|excellent|love it|brilliant)\b"),
}


def split_own_words(text):
    """(participant's own words, pasted material) of one prompt."""
    text = re.sub(r"```.*?(?:```|$)", "\n", text, flags=re.S)       # fenced blocks are pasted
    own, pasted = [], []
    for line in text.splitlines():
        s = line.strip()
        if not s:
            continue
        letters = sum(c.isalpha() or c == " " for c in s) / len(s)
        if LOGLINE.search(s) or LOGCAPS.search(s) or CODELINE.search(s) or letters < 0.75 or \
           (len(s) > 200 and s.count(" ") < len(s) / 12):
            pasted.append(s)
        else:
            own.append(s)
    return "\n".join(own), "\n".join(pasted)


VIETNAMESE = re.compile(r"[ăâđêôơưạảấầẩẫậắằẳẵặẹẻẽếềểễệỉịọỏốồổỗộớờởỡợụủứừửữựỳỵỷỹ]", re.I)


def english(text):
    """False for prompts written mainly in Vietnamese, which the English keywords cannot code."""
    own, _ = split_own_words(text)
    return len(VIETNAMESE.findall(own)) < max(3, len(own) // 60)


def markers(text):
    """Set of marker names for one prompt."""
    own, pasted = split_own_words(text)
    found = {name for name, rx in MARKERS.items() if rx.search(own)}
    if PASTE_NOTE.search(text) or len(pasted.splitlines()) >= 3:
        found.add("pastes_output")
    return found


def error_driven(text):
    m = markers(text)
    return "repeated_error" in m or ("pastes_output" in m and bool(FAILWORD.search(ZERO.sub("", text))))
