package org.elastos.wallet.ela.ui.proposal.fragment;

import android.os.Bundle;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.view.View;
import android.widget.LinearLayout;

import com.scwang.smartrefresh.layout.SmartRefreshLayout;
import com.scwang.smartrefresh.layout.api.RefreshLayout;
import com.scwang.smartrefresh.layout.listener.OnLoadMoreListener;
import com.scwang.smartrefresh.layout.listener.OnRefreshListener;

import org.elastos.wallet.R;
import org.elastos.wallet.ela.base.BaseFragment;
import org.elastos.wallet.ela.rxjavahelp.BaseEntity;
import org.elastos.wallet.ela.rxjavahelp.NewBaseViewData;
import org.elastos.wallet.ela.ui.common.listener.CommonRvListener;
import org.elastos.wallet.ela.ui.proposal.adapter.ProposalRecAdapetr;
import org.elastos.wallet.ela.ui.proposal.bean.ProposalSearch;
import org.elastos.wallet.ela.ui.proposal.presenter.ProposalPresenter;

import java.util.ArrayList;
import java.util.List;

import butterknife.BindView;

;

//承载提案首页viewpager控制的各个item的Fragment
public class ProposalItemFragment extends BaseFragment implements CommonRvListener, OnRefreshListener, NewBaseViewData, OnLoadMoreListener {
    @BindView(R.id.rv)
    RecyclerView rv;
    @BindView(R.id.ll_noproposal)
    LinearLayout llNoproposal;
    @BindView(R.id.srl)
    SmartRefreshLayout srl;
    private String status;
    private List<ProposalSearch.DataBean.ListBean> list;
    private int pageNum = 1;
    private ProposalPresenter presenter;
    private ProposalRecAdapetr adapter;

    @Override
    protected int getLayoutId() {
        return R.layout.fragment_project_item;
    }

    @Override
    protected void setExtraData(Bundle data) {
        super.setExtraData(data);
        status = data.getString("status");
    }

    @Override
    protected void initView(View view) {
        mRootView.setBackgroundResource(0);
        srl.setOnRefreshListener(this);
        srl.setOnLoadMoreListener(this);
        //Log.i("????", "initView" + status + firstShow);

        //setUserVisibleHint->initView  所用可能cotext无加载 ifstayus=all这里  其他setUserVisibleHint
    }


    private void setRecycleView(List<ProposalSearch.DataBean.ListBean> data) {
        if (data == null || data.size() == 0) {
            if (pageNum == 1) {
                rv.setVisibility(View.GONE);
                llNoproposal.setVisibility(View.VISIBLE);
            } else {
                showToastMessage(getString(R.string.loadall));
            }

            return;
        }

        if (list == null) {
            list = new ArrayList<>();
        }
        if (pageNum == 1) {
            rv.setVisibility(View.VISIBLE);
            llNoproposal.setVisibility(View.GONE);
            list.clear();
        }

        list.addAll(data);

        if (adapter == null) {
            adapter = new ProposalRecAdapetr(getContext(), list);
            adapter.setCommonRvListener(this);
            rv.setLayoutManager(new LinearLayoutManager(getContext(), LinearLayoutManager.VERTICAL, false));
            rv.setAdapter(adapter);
        } else {
            adapter.notifyDataSetChanged();
        }

        pageNum++;
    }

    boolean firstShow = true;

    @Override
    public void setUserVisibleHint(boolean isVisibleToUser) {
        super.setUserVisibleHint(isVisibleToUser);
        //Log.i("????", isVisibleToUser + status + firstShow);
        if (isVisibleToUser && firstShow) {
            presenter = new ProposalPresenter();
            presenter.proposalSearch(pageNum, 20, status, null, this);
            firstShow = false;
        }
    }

    @Override
    public void onRvItemClick(int position, Object o) {
        Bundle bundle = new Bundle();
        ProposalSearch.DataBean.ListBean bean = (ProposalSearch.DataBean.ListBean) o;
        bundle.putInt("id", bean.getId());
        ((BaseFragment) getParentFragment()).start(PropasalReviewFragment.class, bundle);

    }

    public static ProposalItemFragment getInstance(String tag) {
        ProposalItemFragment proposalItemFragment = new ProposalItemFragment();
        Bundle bundle = new Bundle();
        bundle.putString("status", tag);
        proposalItemFragment.setExtraData(bundle);
        return proposalItemFragment;
    }

    @Override
    public void onGetData(String methodName, BaseEntity baseEntity, Object o) {
        switch (methodName) {
            case "proposalSearch":
                setRecycleView(((ProposalSearch) baseEntity).getData().getList());
                break;
        }
    }

    @Override
    public void onRefresh(RefreshLayout refreshLayout) {
        onErrorRefreshLayout(srl);
        pageNum = 1;
        presenter.proposalSearch(pageNum, 20, status, null, this);
    }

    @Override
    public void onLoadMore(RefreshLayout refreshLayout) {
        onErrorRefreshLayout(srl);
        presenter.proposalSearch(pageNum, 20, status, null, this);
    }


}
