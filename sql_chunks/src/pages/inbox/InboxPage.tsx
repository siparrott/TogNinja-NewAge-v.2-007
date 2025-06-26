import React from 'react';
import NextGenInbox from '../../components/inbox/NextGenInbox';

const InboxPage: React.FC = () => {
  return (
    <div className="h-screen bg-gray-50">
      <NextGenInbox />
    </div>
  );
};

export default InboxPage;

  const handleSend = async () => {
    if (!active || !reply.trim()) return;
    await sendMessage({
      to: active[0].from_email,
      subject: `Re: ${active[0].subject}`,
      body: reply,
      thread_id: active[0].thread_id,
    });
    setReply('');
  };

  return (
    <div style={{ display: 'flex', height: '100%' }}>
      {/* Thread list */}
      <aside style={{ width: 260, borderRight: '1px solid #eee', overflowY: 'auto' }}>
        {threads.map((t) => (
          <div
            key={t[0].thread_id}
            onClick={() => setActive(t)}
            style={{
              padding: 12,
              cursor: 'pointer',
              background: active?.[0].thread_id === t[0].thread_id ? '#f5f5f5' : undefined,
              borderBottom: '1px solid #f0f0f0',
            }}
          >
            <strong>{t[0].subject}</strong>
            <br />
            <small>{t[0].from_email}</small>
          </div>
        ))}
      </aside>

      {/* Thread view */}
      <main style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
        <div style={{ flex: 1, overflowY: 'auto', padding: 16 }}>
          {active ? (
            active.map((m) => (
              <div key={m.id} style={{ marginBottom: 16 }}>
                <div>
                  <strong>{m.from_email}</strong> –{' '}
                  {new Date(m.created_at).toLocaleString()}
                </div>
<div dangerouslySetInnerHTML={{ __html: marked.parse(m.body) }} />
              </div>
            ))
          ) : (
            <p style={{ color: '#888' }}>Select a conversation</p>
          )}
        </div>

        {/* Reply box */}
        {active && (
          <div style={{ borderTop: '1px solid #eee', padding: 12 }}>
            <textarea
              value={reply}
              onChange={(e) => setReply(e.target.value)}
              rows={3}
              style={{ width: '100%', resize: 'vertical' }}
              placeholder="Type your reply..."
            />
            <button onClick={handleSend} disabled={!reply.trim()} style={{ marginTop: 6 }}>
              Send
            </button>
          </div>
        )}
      </main>
    </div>
  );
};

export default InboxPage;
