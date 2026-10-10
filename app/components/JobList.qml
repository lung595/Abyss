import QtQuick

// The jobs of a SendQueue.js state as a model whose rows survive an update:
// sync() patches the roles that changed and only rebuilds when the ids or
// their order differ. A meter line then touches one role of one row instead
// of recreating every delegate (value 6).
ListModel {
    function _row(job) {
        return {
            "jid": job.id,
            "device": job.device,
            "path": job.path,
            "state": job.state,
            // -1 for "unknown": a ListModel role cannot hold null
            "progress": job.progress === null ? -1 : job.progress,
            "reason": job.reason
        };
    }

    function sync(jobs) {
        let same = count === jobs.length;
        for (let i = 0; same && i < count; i++)
            same = get(i).jid === jobs[i].id;
        if (!same) {
            clear();
            for (const job of jobs)
                append(_row(job));
            return;
        }
        for (let i = 0; i < count; i++) {
            const row = _row(jobs[i]);
            const cur = get(i);
            for (const key in row)
                if (cur[key] !== row[key])
                    setProperty(i, key, row[key]);
        }
    }
}
