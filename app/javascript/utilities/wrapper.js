import NProgress from 'nprogress';

export const wrap_fetch = fetch_fn => {
  return function (...args) {
    if (this.fetching) {
      return;
    }

    this.fetching = true;
    NProgress.start();

    const show_message = (type, message) => this.$emit('message', { type, message, });
    fetch_fn.bind(this)(...args)
      .then(response => {
        NProgress.done();
        this.fetching = false;
        response && response.status === 500 ?
          show_message('error', response.statusText) :
          show_message('info', 'success');
      })
      .catch(error => {
        NProgress.done();
        this.fetching = false;
        show_message('error', error);
      });
  };
};

